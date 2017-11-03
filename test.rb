require 'capybara/dsl'
require 'rspec/expectations'
require 'ffaker'
require 'timeout'
Capybara.default_driver = :selenium
include FFaker::Internet
include Capybara::DSL
include RSpec::Matchers

def generate_password
  chars = ['0'..'9','a'..'z','A'..'Z'].map{ |r| r.to_a }.flatten
  Array.new(8){ chars[ rand( chars.size ) ] }.join
end

def generate_username
  FFaker::Internet.user_name
end

def generate_email(name=nil)
  if name
    FFaker::Internet.email name
  else
    FFaker::Internet.email
  end

end



def registration_in_dosug(session=nil,email=nil)
  session = init_session(session)
  username,password,email = generate_information_about_user(email)
  session.visit 'https://www.vashdosug.ru/'
  session.click_on "регистрация"
  session.fill_in :id => "signupform-name", :with => username
  session.fill_in :id => "signupform-email", :with => email
  session.fill_in :id => "signupform-password", :with => password
  session.fill_in :id => "signupform-password_repeat", :with => password
  session.click_on "Зарегистрироваться"
  [username,email,password]
end

def registration_in_dev(session=nill,email=nil)
  if !session
    session = Capybara::Session.new(:selenium)
  end
  session.visit 'https://dev.by/registration'
  username = generate_username
  if !email
    email = generate_email username
  end
  password = generate_password
  session.fill_in 'Юзернейм',:with =>username
  session.fill_in 'Емейл адрес', :with => email
  session.fill_in 'Пароль', :with => password
  session.fill_in :id => 'user_password_confirmation', :with => password
  session.check :id =>"user_agreement"
  session.click_on "Зарегистрироваться"
  [username,email,password]
end

def get_email(session=nil)
  session = init_session(session)
  session.visit 'https://temp-mail.org/ru/'
  a = session.find(".mail.opentip")
  a[:value]
end

def confirm_email(session=nil)
  session = init_session(session)
  trying = 0
  find = nil
  while 1
    begin
    (link = session.find("a.title-subject"))
    break
    rescue
    if trying == 20
      break
    end
    refresh = session.find("a#click-to-refresh.no-ajaxy")
    refresh.click
    trying+=1
  end
  end
  if trying < 20
    link.click
    confirm = session.find("div.pm-text").find_link("a")
    confirm.click
  end
  trying
end

def generate_information_about_user(email=nil)
  username = generate_username
  if !email
    email = generate_email username
  end
  password = generate_password
  [username,password,email]
end

def init_session(session = nil)
  if !session
    session = Capybara::Session.new(:selenium_chrome)
    session.html
  end
  session
end

def pass_registration_in_7_days(session=nil,email=nil)
  session = init_session(session)
  username,password,email = generate_information_about_user(email)
  session.visit "https://7days.ru/user/registration.php"
  trying = 0
    session.fill_in "Логин (не менее 3 символов)", :with => username
    session.fill_in "Электронная почта", :with => email
    session.fill_in "Пароль (не менее 6 символов)", :with => password
    session.fill_in "Повторите пароль", :with =>password
    session.click_on "Готово"
  begin
  session.find("input#fRegSubmit.b-form-field__box")
  [username,password,email,nil]
  rescue
    [username,password,email,1]
  end

end

def registration_in_7_days(session=nil,email=nil)
    session = init_session
    email = get_email(session)
    username,password,email,trying = pass_registration_in_7_days(nil,email)
    if !trying
      return nil
    end
    trying = confirm_email session
    if trying != 20
      return 1
    else
      return nil
    end
  [username,password,email]
end

success = 0
while success < ARGV[0].to_i
  begin
  status = Timeout::timeout(ARGV[1].to_i) {
    if registration_in_7_days
      success +=1
    end
  }
  rescue
  end

end