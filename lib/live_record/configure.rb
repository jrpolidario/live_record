require 'ostruct'

module LiveRecord

  class Configuration < OpenStruct
  end

  @configuration = Configuration.new(
    sync_record_buffer_time: 1.minute
  )

  class << self
    attr_accessor :configuration

    def configure(&block)
      block.call(@configuration)
    end
  end
end