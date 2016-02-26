(require file)

(file#open ">/tmp/t.txt" (fn [f]
  (file#>> f "aaa")))

(file#open "</tmp/t.txt" (fn [f]
  (println (perl->clj (file#<< f)))))
