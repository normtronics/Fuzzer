Fuzzer
======

1. Navigate to unzipped directory using bash.
2. Confirm that the files 'fuzz' and 'Gemfile' are included in the directory 'Fuzzer'.
3. Run 'bundle install' in the 'Fuzzer' directory, if the command fails, either
	a. install bundler with the command: 'gem install bundler' and re-run the command
	b. or install the individual necessary gems with: 'gem install mechanize' and 'gem install gli'
4. Once completed, run fuzz with the any of the following commands:
	a. 'ruby fuzz --help'  for the top level commands
	b. 'ruby fuzz discover --help' for the discover commands
	c. 'ruby fuzz discover --common-words=src/Test/common-words.txt [url to fuzz]'


notes:
	- the common words file is located at path "src/Test/common-words.txt"
	- when finding links, the fuzzer recurses through the website, and therefore moves rather slowly
	- url should be either '127.0.0.1/dvwa/login.php' or '127.0.0.1:8080/bodgeit'