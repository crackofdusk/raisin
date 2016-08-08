require_relative './raisin'

module Raisin
  @@at_exit_registered ||= false

  def self.autorun
    unless @@at_exit_registered
      at_exit { TestSuite.run }
      @@at_exit_registered = true
    end
  end
end

Raisin.autorun
