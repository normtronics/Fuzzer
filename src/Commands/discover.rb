require 'rubygems'
require 'mechanize'
require 'uri'
require 'http-cookie'


class Discover

	def initialize(commonWords, page)
		f = File.open(commonWords, "r")
		@agent = Mechanize.new
		@page = page
		@base = ''
		@links = Array.new


		begin
			@commonArray = Array.new
			f.each_line do |line|
  				@commonArray.push(line.chomp)
  				#puts line
			end
			f.close
		rescue SystemCallError
			puts 'IO Failed. Check file path'
			f.close
			File.delete(commonWords)
			raise
		end	

		athenticate()
		puts '------------Finding Links-------------'
		findLinks(@page)
		pageGuess()
		puts '------------Discovering Inputs-------------'
		discoverInputs()
		puts '-------------Getting Cookies---------------'
		puts getCookies()
	end
	
	def findLinks(page)
		page.links.each do |l|
			if l.href.to_s.include?'logout'
				next
			end
			begin
				currPage = l.click()
				if not currPage.uri.host == @base
					next
				end
				if not currPage.uri.to_s.include?'../' and not @links.include?currPage.uri 
					puts 'Found link: ' + currPage.uri.to_s
					@links.push currPage.uri
					findLinks currPage
				end
			rescue Mechanize::ResponseCodeError

			end
		end

	end

	def getURL( link )
		return @base + link.href
	end

	def athenticate
		puts '------------Authenticating-------------'
		page = @agent.get(@page)
		
		if page.uri.to_s.include?("dvwa")
			form = page.forms.first 

			form['username'] = "admin"
			form['password'] = "password"
			page2 = form.click_button

			#Might want to iterate through page to really check if its the same
			if page2.title.eql?(page.title)
				puts 'Login did not work'
			else
				puts 'Successfully logged in'
				@page = page2
				@base = @page.uri.host
			end
		elsif page.uri.to_s.include?("bodgeit")
		
			link = page.link_with(text: 'Login')
			page = link.click
			link = page.link_with(text: 'Register')
			page = link.click
			
			form = page.forms.first
			form['username'] = "my@fuzz.com"
			form['password1'] = "password"
			form['password2'] = "password"
			button = form.button_with(:value => "Register")
			page = @agent.submit(form, button)
			
			if page.links.include?(page.link_with(text: 'Login'))
				link = page.link_with(text: 'Login')
				page = link.click
				form = page.forms.first
				form['username'] = "my@fuzz.com"
				form['password'] = "password"
				button = form.button_with(:value => "Login")
				page = @agent.submit(form, button)
			end
			
			link = page.link_with(text: 'Home')
			@page = link.click
			
			if @page.links.include?(@page.link_with(text: 'Login'))
				puts 'Login did not work'
			else
				puts 'Successfully logged in'
			end
			
			@base = @page.uri.host
			
		end
	end

	def pageGuess
		puts '----------Guessing Pages--------------'
		fileExtensions = ['.php', '.jsp', '.html', '.asp', '.apsx', '.js']
		@commonArray.each do |word|
			@links.each do |link|
				fileExtensions.each do |ext|
					begin
						url = link.to_s + '/' + word + ext
						page = @agent.get(url)
						puts 'Found page: ' + url
					rescue Mechanize::ResponseCodeError
						#puts 'Could not find page: ' + url
					end
				end
			end
		end
	end

	def parseUrl( page, inputs)
	
		page.uri.query.to_s.split('&').each do | input |
			inputs.push input.split('=')[0]
		end

	end

	def discoverInputs

		@links.each do | l |
			inputs = Array.new
			page = @agent.get(l)
			puts page.uri
			forms = page.forms()
			forms.each_with_index do | f | 
				f.keys.each do | key | 
					inputs.push( key )
					f[key] = "input"
				end
				begin
					currPage = f.click_button
				rescue Mechanize::ResponseCodeError
					next	
				end
				parseUrl(currPage, inputs)
			end
			if( not page.at('input') == nil)
				page.at('input').attributes.each do | a |		
					if( a[1].value == 'text')
						next
					end
					inputs.push a[1].value
				end
			end
			if( not inputs.empty? )
				puts "    " + inputs.uniq.to_s
			end
		end
	end

	def getCookies
		return @agent.cookies.to_s
	end

	def getBasePath(page)
		uri = URI.parse(page.uri.to_s)
		path = uri.path.split('/')
		host = uri.host
		path.delete("")
		if path.last.include?(".")
			path.pop
		end
		path.each do |p|
			host = host + '/' + p
		end
		#puts uri.scheme + '://' + host + '/'
		return uri.scheme + '://' + host + '/'
	end

end


def main()
	discover = Discover.new( '../Test/common-words.txt', "http://127.0.0.1:8080/bodgeit/")
	discover.discoverInputs
end


main()
