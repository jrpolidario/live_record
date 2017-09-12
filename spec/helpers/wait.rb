module SpecHelpers
  module Wait
    # Wait before the value of the "before" Proc becomes "becomes",
    # but only wait until "duration" number of seconds,
    # while checking the value each "interval" seconds interval.
    def wait(duration: 5.seconds, interval: (0.5).second, before:, becomes:)
      # use a different thread to prevent blocking the main thread due to sleep()
      Thread.new do
        start = Time.now

        loop do
          break if becomes.call(before.call)
          sleep interval.seconds
          break if (Time.now - start).seconds > duration
        end
      end.join
    end
  end
end