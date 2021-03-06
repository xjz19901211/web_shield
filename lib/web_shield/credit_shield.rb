module WebShield
  class CreditShield < Shield

    # Options:
    #   default_user_credit: options, default 60
    #   default_ip_credit: options, default 600
    #   period: options, credit period, default 60
    #   credit_analyzer_class: CreditAnalyzer
    allow_option_keys(
      :default_user_credit, :default_ip_credit, :period,
      :credit_analyzer_class
    )

    attr_reader :credit_analyzer

    def initialize(*args)
      super
      options[:default_user_credit] ||= 60
      options[:default_ip_credit] ||= 600
      options[:period] ||= 60
      options[:credit_analyzer_class] ||= CreditAnalyzer
      @credit_analyzer = options[:credit_analyzer_class].new(self)
    end

    def filter(request)
      ip = request.ip
      user = config.user_parser.call(request)

      analyze_request(ip, user, request)

      if check_request(ip, user)
        write_log(:debug, "Pass '#{user}-#{ip}'")
        :pass
      else
        write_log(:debug, "Block '#{user}-#{ip}'")
        :block
      end
    end

    def check_request(ip, user)
      incr_opts = if (period = options[:period]) > 0
        {expire_at: (Time.now.to_i / period + 1).to_i * period}
      else
        {}
      end

      [
        [:u, user, options[:default_user_credit]],
        [:ip, ip, options[:default_ip_credit]]
      ].all? do |source_type, source, default_credit|
        next true unless source
        credit = config.store.get(get_credit_key(source_type, source))
        credit = credit ? credit.to_i : default_credit

        if credit <= 0
          write_log(:debug, "block #{source_type}-#{source}: credit eql #{credit}")
          next false
        end

        counter_key = get_request_counter_key(source_type, source)
        ((req_c = config.store.incr(counter_key, incr_opts)) <= credit).tap do
          write_log(:debug, "block #{source_type}-#{source}: req(#{req_c}) > #{credit}")
        end
      end
    end

    # type: u or ip
    # name: user identifier or ip
    def get_request_counter_key(type, name)
      generate_store_key("#{type}-r:#{name}")
    end

    # type: u or ip
    # name: user identifier or ip
    def get_credit_key(type, name)
      generate_store_key("#{type}-c:#{name}")
    end


    private

    def analyze_request(ip, user, request)
      header = request.env.select {|k, v| k =~ /^HTTP_/ }
      credit_analyzer.analyze(ip, user, header, request.params.to_hash)
    end
  end
end

