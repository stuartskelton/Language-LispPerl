(def a 'b)
((fn [b & c]
  (def a 'c)
  (println a)
  (println b)
  (println c))
 'a 'c 'e
)
(defmacro c [a & d]
  `(println ~a))

(c 'b)
(c '(a b c) 'd)

(println (car '(a b c)))
(println (cdr '(a b c)))
(println (cons 'b '(a b c)))

(println (list 'b '(a b c)))

(println ['a 'b 'c])
(println {:abc 'b})

(println (length (list 'b '(a b c))))

(println (length ['a 'b 'c]))
(println (length {:abc 'b}))

(println (length "abcde"))

(println (! false))

(println (eq "a" "b"))
(println (eq "a\n" "a\n"))

(defmacro defn [name args & body]
  `(def ~name
     (fn ~args ~@body)))

(defn foo [a]
  (println a))

(if true
  (println 'true)
; ljfdljd
  (println 'false)) 

(if false
  (println 'true)
  (println 'false))

(def i 0)
(def cond true)
(println i)
(println (+ i 1))
(while cond
  (if (> i 3) (set! cond false))
  (set! i (+ i 1))
  (println i))

(foo "asjfl\tdjsdfd!") ;yyy

(foo 1233434)

(foo :abc)

(println (equal "a" 1))
(println (equal "a" "a"))
(println (equal () ()))
(println (equal :a :b))
(println (equal :a :a))
(println (equal 'a 'b))
(println (equal 'a 'a))


(def m {:abc 100})
(println (:abc m))
(:abc m 101)
(println (:abc m))

(set! m [102 103])
(println (0 m))
(1 m 101)
(println (1 m))


(.CljPerl print "aaa\n")

(println (. print "bbb\n"))

(println (eval "(+ 1 2)"))

(def ^{:a 'b} m 1)
(println (meta m))
(println (type m))
(:a (meta m) 'c)
(println (meta m))

(require "../lib/core.clp")

(defmulti mf type)
(println (meta mf))
(defmethod mf "string" [a] (println "string"))
(defmethod mf "keyword" [a] (println "keyword"))
(println (meta mf))
(mf "a")
(mf :b)

(apply println '(:a))

(defn bar [afn arg]
  (afn arg))

(bar println :b)

(def bar println)
(bar :bar)

(println (reduce (fn [a i]
  (cons (+ a 1) i))
  '()
  '(1 2 3)))

(set! i 0)
((fn [a] (set! a i)) 1)
(println i)

(meta i ^{:a 1})
(println (meta i))

(println (append "abc" "def"))
(println (append '(a b c) '(def)))
(println (append [:a :b :c] [:a :b :c]))
(println (append {:a :b} {:c :d}))

(println (keys {"a" :b :c :d}))
(println ("a" {"a" :b}))

(println (map (fn [i]
   (+ i 1))
  `(1 2 3)))
