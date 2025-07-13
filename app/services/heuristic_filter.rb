class HeuristicFilter
  ACTION_KEYWORDS = %w[
    need should must let's remember investigate check follow rollback
    deploy restart fix update record log track document severity sev
    affected impact down issue problem error failing broken stuck timeout
    cpu memory database db spike high low slow latency resolved fixed
    mitigated root cause identified rolling starting initiated
  ].freeze

  SKIP_PATTERNS = [
    /^\s*$/,                          
    /^(ok|okay|sure|yes|no|yeah)$/i, 
    /lunch|food|coffee|ramen/i,      
    /^\.{3,}$/,                       
    /^-+$/,                           
  ].freeze

  ACTION_PATTERNS = [
    /\b(need|should|must|have to|let's|can someone|remember to)\b/i,
    /\b(investigate|check|follow up|look into|dig into)\b/i,
    /\b(rollback|roll back|revert|deploy|restart|bounce)\b/i,
    /\b(sev-?\d|severity|p\d|priority)\b/i,
    /\b(affected|impact|down|degraded|failing|broken)\b/i,
    /\b(cpu|memory|disk|database|db|cache|queue)\s+(is|at|spike|high|low)/i,
    /\b(error|exception|timeout|latency|spike|threshold)\b/i,
    /\b(record|document|update|add|log|track)\s+(this|that|it)/i,
    /\b(rolling back|rollback\s+(started|initiated)|starting\s+rollback)\b/i,
    /\b(resolved|fixed|issue\s+is\s+resolved|impact\s+(mitigated|resolved))\b/i,
    /\b(root\s+cause|caused\s+by|identified\s+as|turns\s+out)\b/i,
  ].freeze

  def self.pass?(message_text)
    return false if message_text.nil? || message_text.strip.empty?
    
    return false if SKIP_PATTERNS.any? { |pattern| message_text.match?(pattern) }
    return true if ACTION_PATTERNS.any? { |pattern| message_text.match?(pattern) }
    
    text_lower = message_text.downcase
    ACTION_KEYWORDS.any? { |keyword| text_lower.include?(keyword) }
  end

  def self.analyze(message_text)
    return { pass: false, reason: "empty" } if message_text.nil? || message_text.strip.empty?
    
    SKIP_PATTERNS.each do |pattern|
      return { pass: false, reason: "skip_pattern: #{pattern}" } if message_text.match?(pattern)
    end
    
    ACTION_PATTERNS.each_with_index do |pattern, idx|
      return { pass: true, reason: "action_pattern_#{idx}" } if message_text.match?(pattern)
    end
    
    text_lower = message_text.downcase
    ACTION_KEYWORDS.each do |keyword|
      return { pass: true, reason: "keyword: #{keyword}" } if text_lower.include?(keyword)
    end
    
    { pass: false, reason: "no_match" }
  end
end 