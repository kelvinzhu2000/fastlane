require 'vault'
require 'base64'

module Fastlane
  module Helper
    class VaultClientHelper
      #MATCH_PATH = "match"
      attr_reader :address
      attr_reader :match_path
      attr_reader :token

      def initialize(address: nil, token: nil, vault_client: nil, v_match_path: nil)
        @address = address
        @token = token

        @client = vault_client
        @match_path = v_match_path
      end

      def download_file(vault_mount, vault_path, file_path)
        objget = client.kv(vault_mount).read("#{vault_path}/#{match_path}/#{file_path}")

        return Base64.decode64(objget.data[:value])
      end

      # file_data is an actual File object here
      def upload_file(vault_mount, vault_path, file_path, file_data)
        client.kv(vault_mount).write("#{vault_path}/#{match_path}/#{file_path}", value: "#{Base64.encode64(file_data.read)}")
      end

      def delete_file(vault_mount, vault_path, file_path)
        # throw nope
        raise "Vault Delete operation untested at this time. Will not delete."
        #client.kv(vault_mount).delete("#{vault_path}/#{file_path}")
      end

      def list_secrets_recurse(vault_mount, vault_path, base_path)
        arr = []
        client.kv(vault_mount).list("#{vault_path}").each do |cliobj|
          if cliobj.end_with?("/") then
            arr.concat(list_secrets_recurse(vault_mount, "#{vault_path}/#{cliobj.chomp("/")}", "#{base_path}/#{cliobj.chomp("/")}"))
          else
            if base_path == nil
              arr.push(cliobj)
            else
              arr.push("#{base_path}/#{cliobj}".reverse.chomp("/").reverse)
            end
          end
        end
        if arr.length() == 0
          return nil
        end
        return arr
      end

      def list_secrets!(vault_mount, vault_path)
        return list_secrets_recurse(vault_mount, "#{vault_path}/#{match_path}", nil)
      end

      private

      def client
        @client ||= Vault::Client.new(
          {
            address: address,
            token: token
          }.compact
        )
      end
    end
  end
end
