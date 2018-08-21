SHANNON_ENTROPHY_THRESHOLD = 8.freeze
SENSITIVE_WORDS = %w{
  password
  key
  id
  root
  passcode
  ip
  server
  account
  user
  uname
  aws
  aliyun
  token
  host
  port
  username
  database
  mysql
  postgres
  oracle
  secret
}.freeze
KEY_WORDS = [
  %r{key['"]?\s{0,5}(:|=>|=|==)\s{0,5}['"]?[a-z0-9A-Z_@]{10,50}\W}i,
  %r{\Waccount\W}i,
  %r{\Wuser\W}i,
  %r{\Wuname\W}i,
  %r{\Wuser_?name\W}i,
  %r{\Waws\W}i,
  %r{\Wsecret\W}i,
  %r{\Wsecret['"]?\s{0,5}(:|=>|=|==)\s{0,5}['"]?[a-z0-9A-Z_@]{4,50}}i,
  %r{\Wserver\W}i,
  %r{\Wrsa\W}i,
  %r{\Wlogin\W}i,
  %r{\Wpassw(or)?d\W}i,
  %r{\Wpassw(or)?d['"]?\s{0,5}(:|=>|=|==)\s{0,5}['"]?[a-z0-9A-Z_@]{4,50}\W}i,
  %r{\Wpass_?phrase\W}i,
  %r{\Wpass_?phrase['"]?\s{0,5}(:|=>|=|==)\s{0,5}['"]?[a-z0-9A-Z_@]{4,50}\W}i,
  %r{\Wtoken\W}i,
  %r{\Wauth\W}i,
  %r{\Wauthenticat(e|ion)\W}i,
  %r{\Wip\W}i,
  %r{\Wapi\W}i,
  %r{\W("\|')?(aws)?_?(secret)?_?(access)?_?(key)(\"|')?\s*(:|=>|=|==)\s*(\"|')?[A-Za-z0-9/\+=]{40}("\|')?\W}i,
  %r{\W(\"|')?(aws)?_?(account)_?(id)?(\"|')?\s*(:|=>|=)\s*("\|')?[0-9]{4}\-?[0-9]{4}\-?[0-9]{4}("\|')?\W}i,
].freeze
TAG_RESULT_DIR = Rails.root.join('..', 'tag_result').freeze
LEAKED_DIR = Rails.root.join('..', 'tag_result', 'leaked').freeze
NORMAL_DIR = Rails.root.join('..', 'tag_result', 'normal').freeze

unless Dir.exist?(TAG_RESULT_DIR)
  FileUtils.mkdir(TAG_RESULT_DIR)
  FileUtils.mkdir(LEAKED_DIR)
  FileUtils.mkdir(NORMAL_DIR)
end