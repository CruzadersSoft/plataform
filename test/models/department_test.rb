require "test_helper"

class DepartmentTest < ActiveSupport::TestCase
  test "requires a church and name" do
    department = Department.new(name: "")

    assert_not department.valid?
    assert_includes department.errors[:church], "must exist"
    assert_includes department.errors[:name], "can't be blank"
  end

  test "defaults to active" do
    department = Department.new(church: churches(:grace), name: "Kids")

    assert department.active?
  end

  test "allows the same name in different churches" do
    department = Department.new(church: churches(:hope), name: departments(:welcome).name)

    assert department.valid?
  end

  test "scope active returns only active departments" do
    departments(:welcome).update!(active: false)

    active = Department.where(church: churches(:grace)).active

    assert_not_includes active, departments(:welcome)
    assert_includes active, departments(:worship)
  end
end
