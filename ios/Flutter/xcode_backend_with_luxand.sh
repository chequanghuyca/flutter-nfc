#!/bin/sh

set -eu

luxand_env_file="$SRCROOT/../.luxand.env.json"
if [ -f "$luxand_env_file" ]; then
  merged_defines=$(
    /usr/bin/ruby -rjson -rbase64 -e '
      env_file = ARGV.fetch(0)
      existing = ARGV.fetch(1, "").split(",").reject(&:empty?)
      existing_keys = {}
      existing.each do |encoded|
        begin
          key = Base64.strict_decode64(encoded).split("=", 2).first
          existing_keys[key] = true unless key.nil? || key.empty?
        rescue ArgumentError
          # Preserve unknown Flutter definitions without trying to replace them.
        end
      end

      local = JSON.parse(File.read(env_file))
      local.each do |key, value|
        next if value.nil? || existing_keys.key?(key)
        existing << Base64.strict_encode64("#{key}=#{value}")
      end
      STDOUT.write(existing.join(","))
    ' "$luxand_env_file" "${DART_DEFINES:-}"
  )
  export DART_DEFINES="$merged_defines"
  echo "note: Added local Luxand defines to the Flutter iOS build."
fi

exec /bin/sh "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" "$@"
