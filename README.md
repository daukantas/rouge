# Rouge [![Build Status](https://secure.travis-ci.org/kivikakk/rouge.png)](http://travis-ci.org/kivikakk/rouge)

**Ruby + Clojure = Rouge.**

Why?

* Clojure is elegant and fun.
* Quick boot time (currently around 0.1s).
* Ruby's gems tend to be modern with decent APIs.

<!-- You can try a Rouge REPL online at **[Try Rouge](http://try.rouge.io)**, or -->

Install the gem to get the local REPL:

``` bash
gem install rouge-lang
rouge
```

You'll see the `user=>` prompt.  Enjoy!

## example

See [boot.rg](https://github.com/kivikakk/rouge/blob/master/lib/boot.rg), but to demonstrate
salient features:

``` clojure
; define a macro
(defmacro defn [name args & body]
  `(def ~name (fn ~name ~args ~@body)))

; call a Ruby method on Kernel (if the ruby namespace is referred)
(defn require [lib]
  (.require Kernel lib))

; call a Ruby method on an Array with a block argument
(defn reduce [f coll]
  (.inject coll | f))

; using Ruby's AMQP gem with an inline block
(.subscribe queue {:ack true} | [metadata payload]
  (puts (str "got a message: " payload))
  (.ack metadata))
```

What about in Rails?

```
$ rails console -- -rrouge
Loading development environment (Rails 4.0.1)
irb(main):001:0> Rouge.repl
Rouge 0.0.16
user=> Entry
ruby/Entry
user=> (.where Entry {:id 1})
  Entry Load (10.5ms)  SELECT "entries".* FROM "entries" WHERE "entries"."id" = 1
#<ActiveRecord::Relation [#<Entry id: 1, user_id: 1, source: "xyz", rendered: "<p>xyz</p>", created_at: "2014-12-20 05:15:28", updated_at: "2015-07-01 10:28:27", timezone: "Australia/Sydney">]>
user=>
```

## TODO

See [TODO](https://github.com/kivikakk/rouge/blob/master/misc/TODO), but big ones
include:

* making seqs nicer
* persistent datastructures everywhere
* defprotocol

## contributions

**Yes, please!**

* Fork the project.
* Make your feature addition or bug fix.
* Add tests!  This is so I don't break your lovely addition in the future by accident.
* Commit and pull request!  (Bonus points for topic branches.)

**Also**, if there's something in particular you want that's missing, feel free to put your vote in by [opening an Issue](https://github.com/kivikakk/rouge/issues/new) so I know where to direct my attention.

## authorship

Original author: [Yuki Izumi](https://github.com/kivikakk).

Unreserved thanks to the following people for their contributions.

* [Anthony Grimes](https://github.com/Raynes)
* [Brian Shirai](https://github.com/brixen)
* [Connor Mendenhall](https://github.com/ecmendenhall)
* [Erik Erwitt](https://github.com/eerwitt)
* [Joel Holdbrooks](https://github.com/noprompt)
* [Misha Moroshko](https://github.com/moroshko)
* [Russell Whitaker](https://github.com/russellwhitaker)
* [Xu Hui Hui](https://github.com/xhh)

## copyright and licensing

The [MIT license](http://opensource.org/licenses/MIT).

Copyright &copy; 2012&ndash;2016 Yuki Izumi

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
