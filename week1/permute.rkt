;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname permute) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
#lang racket

(define (remove el lst)
  (cond
    [(null? lst) '()]
    [(eq? el (car lst)) (cdr lst)]
    [else (cons (car lst) (remove el (cdr lst)))]))

(define (permutations lst)
  (cond
    [(null? lst) '()]
    [(map (lambda (n)
            (cons n (permutations (remove n lst)))) lst)]))
    