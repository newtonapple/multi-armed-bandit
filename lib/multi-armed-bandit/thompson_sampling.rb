module MultiArmedBandit
  class ThompsonSampling
    def self.beta_mean(success, count, alpha, beta)
      fail_count = count - success
      1 / (1 + (fail_count+beta).to_f / (success+alpha))
    end

    attr_reader :name, :arms
    attr_accessor :redis

    def initialize(redis, name, options={})
      @redis, @name, = redis, name
      @arms_key, @means_key = "#{@name}:arms", "#{@name}:means"
    end

    def create!(arms, options={})
      @arms = Set.new arms
      ts = {:alpha=>5, :beta=>5}
      means = []
      @arms.each do |arm|
        ts["#{arm}:count"] = 0
        ts["#{arm}:success"] = 0.0
      end
      ts.merge!(options)

      @alpha, @beta = ts[:alpha].to_f, ts[:beta].to_f
      means = []

      @arms.each do |arm|
        mean = self.class.beta_mean(
          ts["#{arm}:success"],
          ts["#{arm}:count"],
          (ts["#{arm}:alpha"] || @alpha).to_f,
          (ts["#{arm}:beta"] || @beta).to_f
        )
        means << [mean, arm]
      end

      @redis.multi do |r|
        r.mapped_hmset @name, ts
        r.sadd @arms_key, arms
        r.zadd @means_key, means
      end
      self
    end

    def load!
      @arms = Set.new @redis.smembers(@arms_key)
      alpha, beta = @redis.hmget(@name, :alpha, :beta)
      @alpha, @beta = alpha.to_f, beta.to_f
      self
    end

    def delete!
      @redis.multi do |r|
        r.del @means_key
        r.del @name
        r.del @arms_key
      end
    end

    def put(arm, options={})
      ts = {"#{arm}:count" => 0, "#{arm}:success" => 0.0}
      ts.merge! options
      @arms << arm
      @redis.multi do |r|
        r.mapped_hmset @name, ts
        r.sadd @arms_key, arm
      end
      update_mean arm
      self
    end

    def remove(arm)
      @arms.delete arm
      @redis.multi do |r|
        r.srem @arms_key, arm
        r.hdel @name, ["#{arm}:success", "#{arm}:count", "#{arm}:alpha", "#{arm}:beta"]
        r.zrem @means, arm
      end
    end


    def disable(arm)
      @redis.zrem @means, arm
    end

    def draw_multi(n)
      drawn = []
      n.times { drawn << draw }
      drawn
    end

    def draw
      max_arm = @redis.zrange(@means_key, -1, -1)[0]
      @redis.hincrby @name, "#{max_arm}:count", 1
      update_mean(max_arm)
      max_arm
    end

    def update_success(arm, reward=1.0)
      @redis.hincrbyfloat @name, "#{arm}:success", reward
      update_mean(arm)
    end

    def update_mean(arm)
      @redis.zadd @means_key, mean(arm), arm
    end
    alias enable update_mean

    def mean(arm)
      success, count, alpha, beta = @redis.hmget(@name, "#{arm}:success", "#{arm}:count", "#{arm}:alpha", "#{arm}:beta")
      self.class.beta_mean success.to_f, count.to_f, (alpha || @alpha).to_f, (beta || @beta).to_f
    end

    def stats
      arms, state, means = @redis.multi do |r|
        r.smembers(@arms_key)
        r.hgetall @name
        r.zrange @means_key, 0, -1, :with_scores => true
      end

      { :arms => arms, :state => state, :means => means }
    end
  end
end
