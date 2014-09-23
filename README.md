Fuzzer
======

1. Navigate to unzipped directory using bash.
2. Confirm that the files 'fuzz' and 'Gemfile' are included in the directory.
3. Run 'bundle install' in the current directory, if the command fails, either
	a. install bundler with the command: 'gem install bundler'
	b. or install the individual necessary gems with: 'gem install mechanize' and 'gem install gli'
4. Once completed, run fuzz with the commands:
	a. 'ruby fuzz --help'  for the top level commands
	b. 'ruby fuzz discover --help' for the discover commands
	c. 'ruby fuzz discover --common-words=src/Test/common-words.txt [url to fuzz]'


note: the common words file is located at path "src/Test/common-words.txt"
