RSpec.describe RuboCop::Cop::RSpec::FactoryGirl::CreateList do
  subject(:cop) { described_class.new }

  it 'flags usage of n.times with no arguments' do
    expect_offense(<<-RUBY)
      3.times { create :user }
      ^^^^^^^ Prefer create_list.
    RUBY
  end

  it 'flags usage of n.times when FactgoryGirl.create is used' do
    expect_offense(<<-RUBY)
      3.times { FactoryGirl.create :user }
      ^^^^^^^ Prefer create_list.
    RUBY
  end

  it 'ignores create method of other object' do
    expect_no_offenses(<<-RUBY)
      3.times { SomeFactory.create :user }
    RUBY
  end

  it 'ignores create in other block' do
    expect_no_offenses(<<-RUBY)
      allow(User).to receive(:create) { create :user }
    RUBY
  end

  it 'ignores n.times with argument' do
    expect_no_offenses(<<-RUBY)
      3.times { |n| create :user, created_at: n.days.ago }
    RUBY
  end

  it 'ignores n.times when there is no create call inside' do
    expect_no_offenses(<<-RUBY)
      3.times { do_something }
    RUBY
  end

  it 'ignores n.times when there is other calls but create' do
    expect_no_offenses(<<-RUBY)
      used_passwords = []
      3.times do
        u = create :user
        expect(userd_passwords).not_to include(u.password)
        used_passwords << u.password
      end
    RUBY
  end

  include_examples 'autocorrect',
                   '5.times { create :user }',
                   'create_list :user, 5'

  include_examples 'autocorrect',
                   '5.times { create :user, :trait, key: val }',
                   'create_list :user, 5, :trait, key: val'

  include_examples 'autocorrect',
                   '5.times { FactoryGirl.create :user }',
                   'FactoryGirl.create_list :user, 5'
end
