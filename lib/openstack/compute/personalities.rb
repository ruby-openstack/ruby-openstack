module OpenStack
  module Compute
    module Personalities

      # Handles parsing the Personality hash to load it up with Base64-encoded data.
      def self.get_personality(options)
        return if options.nil?
        require 'base64'
        data = []
        itemcount = 0
        options.each do |localpath,svrpath|
          raise OpenStack::Exception::TooManyPersonalityItems, "Personality files are limited to a total of #{MAX_PERSONALITY_ITEMS} items" if itemcount >= MAX_PERSONALITY_ITEMS
          raise OpenStack::Exception::PersonalityFilePathTooLong, "Server-side path of #{svrpath} exceeds the maximum length of #{MAX_SERVER_PATH_LENGTH} characters" if svrpath.size > MAX_SERVER_PATH_LENGTH
          raise OpenStack::Exception::PersonalityFileTooLarge, "Local file #{localpath} exceeds the maximum size of #{MAX_PERSONALITY_FILE_SIZE} bytes" if File.size(localpath) > MAX_PERSONALITY_FILE_SIZE
          b64 = Base64.encode64(IO.read(localpath))
          data.push({:path => svrpath, :contents => b64})
          itemcount += 1
          end
        data
      end
    end
  end
end
