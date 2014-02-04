# vim:set fileencoding=utf-8:

require 'mechanize'
require 'mtk/concurrent/thread_pool'
require 'mtk/util/import'

COOKIE_FILE = 'cookie.yaml'

def init m
  m.user_agent_alias = "Windows Mozilla"
  m.request_headers = {
    'Accept-Language' => 'ja,en-us;q=0.7,en;q=0.3'
  }
end

def login m
  if File.exist?(COOKIE_FILE) 
    m.cookie_jar.load(COOKIE_FILE)
    return
  end

  m.get('http://www.pixiv.net/')
  m.page.form_with(action: '/login.php'){|form|
    next unless form
    form.checkbox_with(name: 'skip').check
    form.field_with(name: 'pixiv_id').value = 'daneta'
    form.field_with(name: 'pass').value = 'kameari'
    form.click_button
  }
  pp m.cookie_jar.save_as(COOKIE_FILE)
end

class Object
  def tap
    pp self
    return self
  end
end

def crawl_works m, page
    page.search('div.works_display a').each do |a| 
      uri = a[:href]
      next_page = m.click(a)
      if uri =~ /\bmode=big\b/i
        crawl_big m, next_page, page
      else
      end
    end
end

def crawl_big m, page, previous_page
  img = page.at('body > img')
  return unless img
  @pool.push_task do
    Mechanize.start{|m2|
      #pp img[:src]
      file = m2.get(img[:src], nil,  page.uri)
      #file.save
    }
  end
end


Thread.abort_on_exception = true
@pool = Mtk::Concurrent::ThreadPool.new(
  max_producer_count: 5,
  max_consumer_count: 200)

@pool.add_producer do
  Mechanize.start{|m|
    init m
    login m

    Dir.chdir('test')

    pp 'aaaa'

    (1..10).each do |idx|
      url = "http://www.pixiv.net/search.php?s_mode=s_tag_full&word=騎乗位&order=date_d&p=#{idx}"
      m.get(url).tap

      links = m.page.links.find_all{|link| link.href =~ /member_illust\.php\?mode=medium&illust_id=\d+$/}
      links.each do |link|
        page = link.click
        crawl_works m, page
      end
    end
  }
end

@pool.join
pp 'bbb'



