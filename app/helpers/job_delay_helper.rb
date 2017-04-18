module JobDelayHelper
  def perform_later(*args)
    set(wait: 5.seconds).perform_later(*args)
  end
end
