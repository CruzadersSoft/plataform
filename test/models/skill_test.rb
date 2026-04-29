require "test_helper"

class SkillTest < ActiveSupport::TestCase
  test "requires a church and name" do
    skill = Skill.new(name: "")

    assert_not skill.valid?
    assert_includes skill.errors[:church], "must exist"
    assert_includes skill.errors[:name], "can't be blank"
  end

  test "name must be unique within the same church" do
    skill = Skill.new(church: churches(:grace), name: skills(:guitar).name)

    assert_not skill.valid?
    assert_includes skill.errors[:name], "has already been taken"
  end

  test "allows the same name in different churches" do
    skill = Skill.new(church: churches(:hope), name: skills(:guitar).name)

    assert skill.valid?
  end

  test "defaults to active" do
    skill = Skill.new(church: churches(:grace), name: "Bateria")

    assert skill.active?
  end

  test "scope active returns only active skills" do
    skills(:sound).update!(active: false)

    active = Skill.where(church: churches(:hope)).active

    assert_not_includes active, skills(:sound)
  end
end
