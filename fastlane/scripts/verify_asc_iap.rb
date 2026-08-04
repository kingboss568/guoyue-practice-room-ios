#!/usr/bin/env ruby
# frozen_string_literal: true

require "base64"
require "json"
require "net/http"
require "openssl"
require "time"
require "uri"

ROOT = File.expand_path("../..", __dir__)
ENV_FILE = File.join(ROOT, ".env.fastlane")
PRODUCTS_PATH = File.join(ROOT, "fastlane/iap/products.json")
PAYWALL_PATH = File.join(ROOT, "fastlane/iap/paywall_review_manifest.json")
EVIDENCE_PATH = File.join(ROOT, "fastlane/iap/asc_iap_verification.json")
ASC_BASE = "https://api.appstoreconnect.apple.com"

def load_env_file(path)
  return unless File.exist?(path)

  File.readlines(path, chomp: true).each do |line|
    next if line.strip.empty? || line.lstrip.start_with?("#")

    key, value = line.split("=", 2)
    next if key.to_s.strip.empty? || value.nil?

    ENV[key.strip] ||= value.strip.gsub(/\A['"]|['"]\z/, "")
  end
end

def base64url(payload)
  Base64.urlsafe_encode64(payload).delete("=")
end

def der_signature_to_raw(signature)
  sequence = OpenSSL::ASN1.decode(signature)
  sequence.value.map { |integer|
    bytes = integer.value.to_s(2)
    bytes = bytes.bytes.drop_while.with_index { |byte, index| byte.zero? && index < bytes.bytes.length - 1 }.pack("C*")
    bytes.rjust(32, "\0")[-32, 32]
  }.join
end

def asc_jwt(key_id:, issuer_id:, key_file:)
  private_key = OpenSSL::PKey::EC.new(File.read(key_file))
  header = { alg: "ES256", kid: key_id, typ: "JWT" }
  payload = {
    iss: issuer_id,
    exp: Time.now.to_i + 20 * 60,
    aud: "appstoreconnect-v1"
  }
  signing_input = [base64url(JSON.generate(header)), base64url(JSON.generate(payload))].join(".")
  der_signature = private_key.dsa_sign_asn1(OpenSSL::Digest::SHA256.digest(signing_input))
  [signing_input, base64url(der_signature_to_raw(der_signature))].join(".")
end

def asc_get(token, path)
  uri = URI("#{ASC_BASE}#{path}")
  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{token}"
  request["Accept"] = "application/json"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  body = response.body.to_s.empty? ? {} : JSON.parse(response.body)
  [response.code.to_i, body]
rescue JSON::ParserError => e
  [599, { "errors" => [{ "title" => "Invalid JSON response", "detail" => e.message }] }]
end

def asc_patch(token, path, payload)
  uri = URI("#{ASC_BASE}#{path}")
  request = Net::HTTP::Patch.new(uri)
  request["Authorization"] = "Bearer #{token}"
  request["Accept"] = "application/json"
  request["Content-Type"] = "application/json"
  request.body = JSON.generate(payload)

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  body = response.body.to_s.empty? ? {} : JSON.parse(response.body)
  [response.code.to_i, body]
rescue JSON::ParserError => e
  [599, { "errors" => [{ "title" => "Invalid JSON response", "detail" => e.message }] }]
end

def api_error_summary(body)
  Array(body["errors"]).map { |error|
    [error["status"], error["code"], error["title"], error["detail"]].compact.join(" ")
  }.join(" | ")
end

def fetch_json(token, path, label, evidence)
  status, body = asc_get(token, path)
  if status >= 200 && status < 300
    body
  else
    evidence["api_errors"] << {
      "label" => label,
      "path" => path,
      "status" => status,
      "summary" => api_error_summary(body)
    }
    nil
  end
end

def update_paywall_manifest(evidence)
  paywall = JSON.parse(File.read(PAYWALL_PATH))
  requirements = paywall.fetch("review_requirements")
  requirements["app_store_connect_product_created"] = evidence.dig("checks", "product_created") == true
  requirements["price_tier_confirmed"] = evidence.dig("checks", "price_schedule_present") == true
  requirements["zh_hant_localization_confirmed"] = evidence.dig("checks", "zh_hant_localization_matches") == true
  # Version attachment is still safest to confirm on the App Store Connect version page.
  requirements["iap_attached_to_app_version"] = evidence.dig("checks", "iap_attached_to_app_version") == true
  paywall["updated_at"] = Time.now.utc.strftime("%Y-%m-%d")
  if requirements.values.all? { |value| value == true }
    paywall["status"] = "ready_for_review"
  else
    paywall["status"] = "pending_app_store_connect_and_recapture"
  end
  File.write(PAYWALL_PATH, JSON.pretty_generate(paywall) + "\n")
end

def main
  update_manifest = ARGV.include?("--update-manifest")
  fix_localization = ARGV.include?("--fix-localization")
  load_env_file(ENV_FILE)

  products = JSON.parse(File.read(PRODUCTS_PATH))
  product = products.fetch("products").first
  bundle_id = products.fetch("bundle_id")
  product_id = product.fetch("product_id")
  expected_localization = product.fetch("localizations").fetch("zh-Hant")

  key_id = ENV["ASC_KEY_ID"] || ENV["APP_STORE_CONNECT_API_KEY_ID"]
  issuer_id = ENV["ASC_ISSUER_ID"] || ENV["APP_STORE_CONNECT_API_KEY_ISSUER_ID"]
  key_file = ENV["ASC_KEY_FILE"] || ENV["ASC_API_KEY_PATH"] || ENV["APP_STORE_CONNECT_API_KEY_PATH"]

  missing = []
  missing << "ASC_KEY_ID" if key_id.to_s.empty?
  missing << "ASC_ISSUER_ID" if issuer_id.to_s.empty?
  missing << "ASC_KEY_FILE" if key_file.to_s.empty?
  abort("Missing ASC API environment: #{missing.join(', ')}") unless missing.empty?
  abort("ASC key file not found: #{key_file}") unless File.exist?(key_file)

  evidence = {
    "schema_version" => 1,
    "checked_at" => Time.now.utc.iso8601,
    "bundle_id" => bundle_id,
    "product_id" => product_id,
    "checks" => {
      "app_found" => false,
      "product_created" => false,
      "product_type_matches" => false,
      "zh_hant_localization_matches" => false,
      "price_schedule_present" => false,
      "iap_attached_to_app_version" => false
    },
    "app" => nil,
    "iap" => nil,
    "localizations" => [],
    "price_schedule" => nil,
    "app_store_versions_checked" => [],
    "api_errors" => [],
    "manual_follow_up" => [
      "Confirm the IAP is attached to the current editable App Store version in the App Store Connect version page.",
      "Upload the final Pro/payment review screenshot after verified audio and artwork gates pass."
    ]
  }

  token = asc_jwt(key_id: key_id, issuer_id: issuer_id, key_file: key_file)

  apps = fetch_json(
    token,
    "/v1/apps?filter[bundleId]=#{URI.encode_www_form_component(bundle_id)}&limit=1",
    "app lookup",
    evidence
  )
  app = apps && Array(apps["data"]).first
  if app
    evidence["checks"]["app_found"] = true
    evidence["app"] = {
      "id" => app["id"],
      "name" => app.dig("attributes", "name"),
      "bundle_id" => bundle_id
    }
  end

  if app
    iaps = fetch_json(
      token,
      "/v1/apps/#{app['id']}/inAppPurchasesV2?limit=200",
      "iap list",
      evidence
    )
    matching_iap = Array(iaps && iaps["data"]).find { |item|
      item.dig("attributes", "productId") == product_id
    }

    if matching_iap
      evidence["checks"]["product_created"] = true
      iap_type = matching_iap.dig("attributes", "inAppPurchaseType")
      evidence["checks"]["product_type_matches"] = iap_type.to_s.upcase.include?("NON_CONSUMABLE")
      evidence["iap"] = {
        "id" => matching_iap["id"],
        "product_id" => matching_iap.dig("attributes", "productId"),
        "reference_name" => matching_iap.dig("attributes", "referenceName"),
        "type" => iap_type,
        "state" => matching_iap.dig("attributes", "state")
      }

      localizations = fetch_json(
        token,
        "/v2/inAppPurchases/#{matching_iap['id']}/inAppPurchaseLocalizations?limit=200",
        "iap localizations",
        evidence
      )
      evidence["localizations"] = Array(localizations && localizations["data"]).map { |item|
        {
          "id" => item["id"],
          "locale" => item.dig("attributes", "locale"),
          "name" => item.dig("attributes", "name"),
          "description" => item.dig("attributes", "description")
        }
      }
      zh_hant = evidence["localizations"].find { |item| item["locale"] == "zh-Hant" }

      if fix_localization && zh_hant
        patch_payload = {
          data: {
            id: zh_hant["id"],
            type: "inAppPurchaseLocalizations",
            attributes: {
              name: expected_localization["display_name"],
              description: expected_localization["description"]
            }
          }
        }
        patch_status, patch_body = asc_patch(
          token,
          "/v1/inAppPurchaseLocalizations/#{zh_hant['id']}",
          patch_payload
        )
        evidence["localization_patch"] = {
          "attempted" => true,
          "status" => patch_status,
          "target_id" => zh_hant["id"],
          "expected_name" => expected_localization["display_name"],
          "expected_description" => expected_localization["description"]
        }
        if patch_status >= 200 && patch_status < 300
          refreshed = fetch_json(
            token,
            "/v2/inAppPurchases/#{matching_iap['id']}/inAppPurchaseLocalizations?limit=200",
            "iap localizations after patch",
            evidence
          )
          evidence["localizations"] = Array(refreshed && refreshed["data"]).map { |item|
            {
              "id" => item["id"],
              "locale" => item.dig("attributes", "locale"),
              "name" => item.dig("attributes", "name"),
              "description" => item.dig("attributes", "description")
            }
          }
          zh_hant = evidence["localizations"].find { |item| item["locale"] == "zh-Hant" }
        else
          evidence["api_errors"] << {
            "label" => "patch iap zh-Hant localization",
            "path" => "/v1/inAppPurchaseLocalizations/#{zh_hant['id']}",
            "status" => patch_status,
            "summary" => api_error_summary(patch_body)
          }
        end
      elsif fix_localization
        evidence["localization_patch"] = {
          "attempted" => false,
          "reason" => "zh-Hant localization not found"
        }
      end

      evidence["checks"]["zh_hant_localization_matches"] =
        zh_hant &&
        zh_hant["name"] == expected_localization["display_name"] &&
        zh_hant["description"] == expected_localization["description"]

      price_schedule = fetch_json(
        token,
        "/v2/inAppPurchases/#{matching_iap['id']}/iapPriceSchedule",
        "iap price schedule",
        evidence
      )
      if price_schedule && price_schedule["data"]
        evidence["checks"]["price_schedule_present"] = true
        evidence["price_schedule"] = {
          "id" => price_schedule.dig("data", "id"),
          "type" => price_schedule.dig("data", "type")
        }
      end
    end

    versions = fetch_json(
      token,
      "/v1/apps/#{app['id']}/appStoreVersions?filter[platform]=IOS&limit=10",
      "app store versions",
      evidence
    )
    evidence["app_store_versions_checked"] = Array(versions && versions["data"]).map { |version|
      {
        "id" => version["id"],
        "version_string" => version.dig("attributes", "versionString"),
        "app_store_state" => version.dig("attributes", "appStoreState"),
        "platform" => version.dig("attributes", "platform")
      }
    }
  end

  File.write(EVIDENCE_PATH, JSON.pretty_generate(evidence) + "\n")
  update_paywall_manifest(evidence) if update_manifest

  puts "ASC IAP verification written: #{EVIDENCE_PATH.sub(ROOT + '/', '')}"
  puts "App found: #{evidence.dig('checks', 'app_found')}"
  puts "IAP product created: #{evidence.dig('checks', 'product_created')}"
  puts "zh-Hant localization matches: #{evidence.dig('checks', 'zh_hant_localization_matches')}"
  if evidence["localization_patch"]
    puts "zh-Hant localization patch: #{evidence['localization_patch']}"
  end
  puts "Price schedule present: #{evidence.dig('checks', 'price_schedule_present')}"
  puts "IAP attached to app version: #{evidence.dig('checks', 'iap_attached_to_app_version')} (manual confirmation required)"
  unless evidence["api_errors"].empty?
    warn "ASC API warnings/errors:"
    evidence["api_errors"].each { |error| warn "- #{error['label']}: #{error['status']} #{error['summary']}" }
  end
end

main
