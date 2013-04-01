# MultiArmedBandit
A Redis backed multi-armed bandit library.  Currently Thompson Sampling is implemented. 

## Usage

```ruby
require 'multi-armed-bandit'
mab = MultiArmedBandit::ThompsonSampling.new Redis.new(:port => 6379), 'colors'
mab.create! ['red', 'green', 'blue'], :alpha => 10, :beta => 10
mab.draw # => 'red'
mab.draw # => 'green'
mab.draw # => 'blue'
mab.draw_multi(3) # => ['red', blue', 'green']

mab.put 'yellow', :alpha => 5, :beta => 5
mab.draw # => 'yellow'
mab.update_success('red')
mab.update_success('green', 2)
mab.draw # => 'green'
mab.remove 'green'
mab.draw # => 'red'
mab.disable 'red'
mab.draw # => 'yellow'
mab.enable 'red'
mab.draw # => 'red'
```

```ruby
mab = MultiArmedBandit::ThompsonSampling.new Redis.new(:port => 6379), 'colors'
mab.load!
mab.stats # => {:arms=>["yellow", "red", "blue"], :state=>{"alpha"=>"5", "beta"=>"5", "red:count"=>"3", "red:success"=>"1", "blue:count"=>"2", "blue:success"=>"0.0", "yellow:count"=>"1", "yellow:success"=>"0.0", "green:count"=>"1"}, :means=>[["blue", 0.45454545454545453], ["green", 0.47619047619047616], ["yellow", 0.47619047619047616], ["red", 0.4782608695652174]]}
```