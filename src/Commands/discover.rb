require 'rubygems'
require 'mechanize'
require 'uri'
require 'http-cookie'


class Fuzzer

	def initialize(uri)
		@agent = Mechanize.new
		@page = @agent.get(uri) 	#starting page
		@base = @page.uri.host		#base of the uri
		@links = Array.new 			#link uri
		@auth = false;				# bool to prevent double auth

		@urlInput = {}				#Hash map url --> uriInput Array
		@vector = Array.new			#test input
		@report = {}

	end


	def discover(commonWordsFile)
		f = File.open(commonWordsFile, "r")

		# ------ Read common work text file
		begin
			@commonArray = Array.new
			f.each_line do |line|
  				@commonArray.push(line.chomp)
			end
			f.close
		rescue SystemCallError
			puts 'IO Failed. Check file path'
			f.close
			File.delete(commonWords)
			raise
		end	
		puts '------------Finding Links-------------'
		findLinks(@page)
		pageGuess()
		discoverInputs()
		puts getCookies()
	end


	def testDiscover(vectorFile, sensitiveDataFile)
		@sensitiveDataFile = sensitiveDataFile
		readVector(vectorFile)
		test()
	 	sanitizationCheck()
	 	#dataLeaked(@page, sensitiveDataFile)
		printReport()
	end


	def findLinks(page)

		if page.uri.to_s.include?'login'
			page = athenticate page
		end

		if page == nil or page.links == nil
			return 
		end

		page.links.each do |l|
			#Dont click on any logout link
			if l.href.to_s.include?'logout'
				next
			end
			begin
				currPage = l.click()
				if not currPage.uri.host == @base	#Dont crawl off the site
					next
				end
				if currPage.uri.to_s.include? 'login' and !@auth # login screen
					athenticate currPage
				end
				# no ../   
				if not currPage.uri.to_s.include?'../'			
					pUri = parseUrl currPage.uri
					# not already visited
					if not  @links.include?pUri 
						puts 'Found link: ' + pUri.to_s
						@links.push pUri
						findLinks currPage
					end
				end
			rescue Mechanize::ResponseCodeError
				next
			rescue Mechanize::ResponseReadError
				next
			end
		end
	end

	def pageGuess
		puts '----------Guessing Pages--------------'
		fileExtensions = ['.php', '.jsp', '.html', '.asp', '.apsx', '.js']
		@commonArray.each do |word|
			@links.each do |link|
				fileExtensions.each do |ext|
					begin
						# removes the ext from the link before adding a new path
						index = -1
						i = 1
						#checks ext up to 6 char long
						while i < 7 do
							curr = link.to_s[-i]
							if curr == "."
								index = -( i + 1)
								break
							end
							i += 1
						end
						url = link.to_s[0 .. index] + '/' + word + ext
						page = @agent.get(url)
						puts 'Found page: ' + url
					rescue Mechanize::ResponseCodeError
						# puts 'Could not find page: ' + url  
					end
				end
			end
		end
	end


	def athenticate page
		puts '------------Authenticating-------------'
		if page.uri.to_s.include?("dvwa")
			form = page.forms.first 

			form['username'] = "admin"
			form['password'] = "password"
			page2 = form.click_button

			if page2.title.eql?(page.title)
				puts 'Login did not work'
			else
				puts 'Successfully logged in'
				@auth = true;
			end

			return page2

		elsif page.uri.to_s.include?("bodgeit")
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
			page = link.click
			
			if page.links.include?(@page.link_with(text: 'Login'))
				puts 'Login did not work'
			else
				puts 'Successfully logged in'
				@auth = true;
			end

			return page
		end

	end



	def parseUrl( uri )

		if uri.query != nil

			i = uri.to_s.index('?') - 1
			key = uri.to_s[0..i]
			if @urlInput[key] == nil
				@urlInput[key] = Array.new
			end

			uri.query.split('&').each do | query |
				# INPUT NAME
				name = query.split('=')[0]
				if not @urlInput[key].include? name
					@urlInput[key].push name
				end
			end
			
			return URI(uri.to_s[0..i])
		else
			return URI(uri.to_s)
		end

	end

	def discoverInputs
		puts '------------Discovering Inputs-------------'
		@links.each do | l |
			inputs = Array.new
			page = @agent.get(l)
			puts page.uri
			forms = page.forms()
			forms.each do | f | 
				f.keys.each do | key | 
					inputs.push( key )
					f[key] = "input"
				end
				begin
					currPage = f.click_button
				rescue Mechanize::ResponseCodeError
					next	
				end
			end
			# get inputs not in forms
			if( not page.at('input') == nil)
				page.at('input').attributes.each do | a |		
					if( a[1].value == 'text')
						next
					end
					inputs.push a[1].value
				end
			end
			# prints tab with inputs
			# todo push to gobal struct
			if( not inputs.empty? )
				puts "    " + inputs.uniq.to_s
			end
		end
	end

	def getCookies
		puts '-------------Getting Cookies---------------'
		return @agent.cookies.to_s
	end

	def readVector( filename )

		f = File.open(filename, "r")
		# ------ Read vector test input text file
		begin
			@vector = Array.new
			f.each_line do |line|
  				@vector.push(line.chomp)
			end
			f.close
		rescue SystemCallError
			puts 'IO Failed. Check file path'
			f.close
			File.delete(filename)
			raise
		end	

	end

	def test()

		puts '----------------- Tests -------------------'
		#triple loop 
		@vector.each do | input | 
			@links.each do | l | 
				currPage = @agent.get(l)

				#try form input
				found = false
				currPage.forms().each do | f |
					f.keys.each do | key |
						if found #prevents double recording vunerability on the same page 
							next
						end
						f[key] = input
						works = true
						#check for DOS
						t1 = Time.now
						begin
							currPage = f.click_button
						rescue Mechanize::ResponseCodeError => e
							#HTTP response codes. 
							#If the HTTP response code is not OK (i.e. 200), then something went wrong. Report it.
							report currPage, 'HTTP Response Code : ' + e.response_code
							found = true
							works = false
						end
						t2 = Time.now

						if( works )
							responseTime = t2 - t1
							if responseTime > 0.5
								report currPage, "Possible DOS"
								found = true
							end
							if dataLeaked currPage, @sensitiveDataFile
								report currPage, "Sensitive data leaked"
							end
						end
					end
				end

				# try url
				key = l.to_s
				if @urlInput[key] != nil
					#test url input
					currLink = key + '&'
					@urlInput[key].each_with_index do | urlInputName, index| 
						currLink = currLink + urlInputName + '=' + input
						if index != @urlInput[key].length - 1
							currLink = currLink + '&'
						end
					end
					#check for DOS
					works = true
					t1 = Time.now
					begin
						currPage = @agent.get currLink
					rescue Mechanize::ResponseCodeError => e
						#HTTP response codes. 
						#If the HTTP response code is not OK (i.e. 200), then something went wrong. Report it.

						# if currPage.uri.query != nil
						# 	puts currPage.uri.path + '?' + currPage.uri.query + " Failed"
						# end
						# puts currPage.uri.path + " Failed  with " + input
						# puts 'HTTP Response Code : ' + e.response_code
						report currPage, 'HTTP Response Code : ' + e.response_code
						works = false
					end
					t2 = Time.now
					if( works and not found )
						responseTime = t2 - t1
						if responseTime > 0.5
							report currPage, "Possible DOS"
						end
						if dataLeaked currPage, @sensitiveDataFile
							report currPage, "Sensitive data leaked"
						end
					end
				end

			end
		end

	end


	def sanitizationCheck 
		sanTest = '<WESTSIDETILLIDIEEASTSIDECONNECTION>'
		@links.each do |l|
			page = @agent.get(l)
			forms = page.forms()
			forms.each do |form|
				inputs = form.fields
				inputs.each do |input|
					input.value = sanTest;
					#puts input.value
				end

				begin
					currPage = form.click_button
					#pp currPage.body

					if currPage.body.to_s.include?('&amplt;WESTSIDETILLIDIEEASTSIDECONNECTION&amp;gt;')
					elsif currPage.body.to_s.include?('lt;WESTSIDETILLIDIEEASTSIDECONNECTION&amp;gt;')
						# report currPage "Lack of sanitization"
					elsif currPage.body.to_s.include?('<WESTSIDETILLIDIEEASTSIDECONNECTION>')
						report currPage, "Lack of sanitization"
					else
						# puts 'Nothing Found, Can not tell'
					end 

				rescue Mechanize::ResponseCodeError => e
					report currPage, 'HTTP Response Code : ' + e.response_code
					next	
				end
			end
		end

	end

	def report page, rpt
		if page == nil or page.uri == nil
			return
		end
		key = page.uri.path 
		if @report[key] == nil
			@report[key] = Array.new
		end
		if not @report[key].include? rpt
			@report[key].push rpt
		end
	end

	def printReport
		@report.keys.each do |key| 
			puts 'Page: ' + key
			puts '        ' +  @report[key].to_s
		end
	end

	# James
	# This function takes a page and parses it for sensitive data 
	# use page.body.to_s to get the html string
	# look for anything that looks like SQL 
	def dataLeaked(page, fileName)
		f = File.open(fileName, "r")
		f.each do |line|
			if page.body.to_s.include?(line.strip)
				return true
			end
		end
		return false
	end

end

def main()
	#discover = Discover.new( 'common-words.txt', "http://127.0.0.1/dvwa/login.php")
	discover = Discover.new( 'common-words.txt', "http://127.0.0.1:8080/bodgeit/")
	discover.readVector('vectors.txt')
	discover.test()
	discover.sanitizationCheck()
	discover.printReport
end


#main()
