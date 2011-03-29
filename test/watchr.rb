# Watchr 'Auto-Test' Config

$module_name = 'downspout'

def lib_trigger(match)
  test_name = match.gsub('lib/','test/test_')
  system("ruby -I'test' #{test_name}")
end

def unit_trigger(match)
  test_name = match.gsub('lib','test').gsub( $module_name, 'unit' ).gsub('.rb','_test.rb')
  system("ruby -I'test' #{test_name}")
end

watch( 'lib/.*\.rb' )  {|md| lib_trigger( md[0] ) }
watch( "lib/#{$module_name }/.*\.rb" )  {|md| unit_trigger( md[0] ) }
watch( 'test/.*_test\.rb' )  {|md| system("ruby -Itest #{md[0]}") }
