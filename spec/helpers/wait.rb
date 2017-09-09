module SpecHelpers
	module Wait
		def wait(duration: 5.seconds, interval: (0.5).second, before:, becomes:)
			start = Time.now

			loop do
	      break if becomes.call(before.call)
	      sleep interval.seconds
	      break if (Time.now - start).seconds > duration
	    end
		end
	end
end