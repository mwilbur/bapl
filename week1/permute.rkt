#lang racket

(define (remove el lst)
  (cond
    [(null? lst) '()]
    [(eq? el (car lst)) (cdr lst)]
    [else (cons (car lst) (remove el (cdr lst)))]))

(define (permutation lst acc)
  (cons (for/list ([n lst])
    (for/list ([p (permutation (remove n lst) acc)])
      (cons n p))) acc))

