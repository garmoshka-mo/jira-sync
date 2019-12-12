class Index < Hash

  def initialize
    super do |hash, key|
      hash[key] = Array.new
    end
  end

end