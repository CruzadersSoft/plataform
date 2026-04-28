class ApplicationServiceResult
  attr_reader :errors

  def initialize(success:, errors: [], **attributes)
    @success = success
    @errors = Array(errors)
    attributes.each do |name, value|
      instance_variable_set(:"@#{name}", value)
      self.class.attr_reader name unless respond_to?(name)
    end
  end

  def success?
    @success
  end
end
