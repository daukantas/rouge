# rouge

Ruby + Clojure = Rouge.

## example

See [boot.rg](https://github.com/unnali/rouge/blob/master/lib/boot.rg),
[em-rg](https://github.com/unnali/em-rg), but to demonstrate salient features:

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

    ; copied from core.clj and modified to work with our currently smaller core
    (defmacro binding [bindings & body]
      (let [var-ize (fn [var-vals]
                      (.flatten
                        (map
                          (fn [pair]
                            (let [key (first pair)
                                  val (second pair)]
                              [`(.name (var ~key)) val]))
                          (.each_slice var-vals 2))
                        1))]
      `(try
         (push-thread-bindings (hash-map ~@(var-ize bindings)))
         ~@body
         (finally
           (pop-thread-bindings)))))

## TODO

See [TODO](https://github.com/unnali/rouge/blob/master/TODO), but big ones
include:

* seqs
* persistent datastructures everywhere
* defprotocol

## contributions

Yes, please!  The usual dance would be:

* Fork.
* Check that tests are passing.  (`master` should always be 100%, but currently
  this is not the case.)
* Make a topic branch.
* Do your tests, do your thing.
* Make sure you didn't break anything!
* Pull request!

Note that I've yet to work out copyright or license (will ask on
`clojure-dev`), but promise that they won't be anything stupid.

## authorship

Original author: Arlen Cuss &mdash; [ar@len.me](mailto:ar@len.me).

Inspiration: 100% [Clojure](https://github.com/clojure/clojure).  Thanks be to
Rich Hickey.

## copyright and licensing

Yet to be determined; likely EPL due to the entire concept and some code taken
direct from Clojure.
