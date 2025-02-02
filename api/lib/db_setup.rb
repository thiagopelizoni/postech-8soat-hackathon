#!/usr/bin/env ruby

def check_db_initialized
    system("bin/rails db:version > /dev/null 2>&1")
end
  
if check_db_initialized
    system("bin/rails db:migrate")
else
    puts "Inicializando banco de dados"
    system("bin/rails db:create")
    system("bin/rails db:migrate")
    system("bin/rails db:seed")
end
  