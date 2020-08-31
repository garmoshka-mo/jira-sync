def error(msg)
  hide_from_stack = true
  err = "😱  #{msg}"
  STDERR.puts err.ljust(80, ' ').red
  binding.pry
  raise msg
end
