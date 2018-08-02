;Matteo Colella - 794028
;Matteo Angelo Costantini - 795125
;Dario Gerosa - 793636

;jsonload
;Return: jsonobj letto da fileName

(defun jsonload (fileName)
  (let ((string (concatenate-strings (get-strings-from-file fileName))))
    (jsonparse string)))



;jsonget
;Return: il value ottenuto "seguendo" i valori di fields

(defun jsonget (object &rest fields)
  (jsonget-aux object fields))

(defun jsonget-aux (object fields)
  (cond
   ((null fields) object)
   ((and (is-jsonarray object) (numberp (first fields)))
    (let ((e (nth (1+ (first fields)) object)))
      (if (equal e nil)
          (error "Index out of bound")
        (jsonget-aux e (rest fields)))))
   ((and (is-jsonobj object) (atom (first fields)))
    (jsonget-aux (get-value (first fields) (rest object)) (rest fields)))
   (T (error "Field is not a number or a key"))
   ))



;FUNZIONI JSONPARSE

;jsonparse
;Return: jsonobj | jsonarray
;La stringa in input deve essere utilizzata completamente

(defun jsonparse (string)
  (multiple-value-bind (json rest)
      (parse-json (coerce string 'list))
    (if (null (remove-spaces rest))
        json
      (error "Syntax error. Rest string: ~S" string)
      )))



;parse-json
;Return: (jsonobj Members) | (jsonarray Elements) - Rest

(defun parse-json (input)
  (let ((skipped (remove-spaces input)))
    (cond
     ((null skipped) (error "Syntax error. Rest string: ~S" skipped))
     ((is-object skipped)
      (multiple-value-bind (object rest_object)
          (parse-object skipped)
        (values object rest_object)))
     ((is-array skipped)
      (multiple-value-bind (array rest_array)
          (parse-array skipped)
        (values array rest_array)))
     (T (error "Syntax error. Rest string: ~S" skipped))
     )))



;parse-array
;Return: (jsonarray Elements) - Rest

(defun parse-array (input)
  (let ((skipped (remove-spaces input)))
    (cond
      ((and (is-array skipped)
            (char= (first (remove-spaces (rest skipped))) #\]))
        (values '(jsonarray) (rest (remove-spaces (rest skipped)))))
      ((is-array skipped)
        (multiple-value-bind (elements rest_elements)
            (parse-elements (rest skipped))
          (values (append '(jsonarray) elements) rest_elements)))
      (T (error "Syntax error. Rest string: ~S" skipped))
      )))


;parse-elements
;Return: (El1 El2 ..) - Rest

(defun parse-elements (input)
  (if (null input)
      (error "Syntax error. Rest string: ~S" input)
    (multiple-value-bind (value rest_value)
        (parse-value (remove-spaces input))
      (let ((skipped (remove-spaces rest_value)))
        (cond
         ((null skipped) (error "Syntax error. Rest string: ~S" skipped))
         ((char= (first skipped) #\]) (values (list value) (rest skipped)))
         (T
          (multiple-value-bind (elements rest_elements)
              (parse-elements (remove-spaces skipped #\,))
            (values (cons value elements) rest_elements)))
         )))))



;parse-object
;Return: (jsonobj Members) - Rest

(defun parse-object (input)
  (let ((skipped (remove-spaces input)))
    (cond
      ((and (is-object skipped)
            (char= (first (remove-spaces (rest skipped))) #\}))
        (values '(jsonobj) (rest (remove-spaces (rest skipped)))))
      ((is-object skipped)
        (multiple-value-bind (members rest_member)
            (parse-member (rest skipped))
          (values (append '(jsonobj)
                          (reverse (remove-occurrences (reverse members))))
                  rest_member)))
      (T (error "Syntax error. Rest string: ~S" skipped))
      )))



;parse-member
;Return: (Pair1 Pair2 ..) - Rest

(defun parse-member (input)
  (if (null input)
      (error "Syntax error. Rest string: ~S" input)
    (multiple-value-bind (pair rest_pair)
        (parse-pair (remove-spaces input))
      (let ((skipped (remove-spaces rest_pair)))
        (cond
         ((null skipped) (error "Syntax error. Rest string: ~S" skipped))
         ((char= (first skipped) #\}) (values (list pair) (rest skipped)))
         (T
          (multiple-value-bind (members rest_member)
              (parse-member (remove-spaces skipped #\,))
            (values (cons pair members) rest_member)))
         )))))



;parse-pair
;Return: (Key Value) Rest

(defun parse-pair (input)
  (multiple-value-bind (key rest_key)
      (parse-key (remove-spaces input))
    (multiple-value-bind (value rest_value)
        (parse-value (remove-spaces rest_key #\:))
      (values (list key value) rest_value))))



;parse-key
;Return: String | Identifier - Rest
;Richiama parse-string o parse-identifier

(defun parse-key (input)
  (cond
   ((or (char= (first input) #\") (char= (first input) #\'))
    (multiple-value-bind (string rest_string)
        (parse-string input)
      (values string rest_string)))
   ((is-char (first input))
    (multiple-value-bind (id rest_id) (parse-identifier input)
      (values (coerce id 'string) rest_id)))
   (T (error "Syntax error. Rest string: ~S" input))
   ))



;parse-value
;Return: String | Number | Json - Rest
;Richiama parse-string, parse-number o parse-json

(defun parse-value (input)
  (let ((skipped (remove-spaces input)))
    (cond
     ((or (char= (first skipped) #\") (char= (first skipped) #\'))
      (multiple-value-bind (string rest_string)
          (parse-string skipped)
        (values string rest_string)))
     ((is-digit (first skipped))
      (multiple-value-bind (number rest_number)
          (parse-number skipped)
        (values number rest_number)))
     (T
      (multiple-value-bind (json rest_json)
          (parse-json skipped)
        (values json rest_json)))
     )))



;parse-string
;Return: "string" - Rest

(defun parse-string (input)
  (cond 
   ((and (char= (first input) #\") (char= (first (rest input)) #\"))
    (values NIL (subseq input 2)))
   ((and (char= (first input) #\"))
    (multiple-value-bind (string rest_string)
        (parse-anychars (rest input) #\")
      (values (coerce string 'string) rest_string)))
   ((and (char= (first input) #\') (char= (first (rest input)) #\'))
    (values NIL (subseq input 2)))
   ((and (char= (first input) #\'))
    (multiple-value-bind (string rest_string)
        (parse-anychars (rest input) #\')
      (values (coerce string 'string) rest_string)))
   (T (error "Syntax error. Rest string: ~S" input))
   ))



;parse-anychars
;Parsa i caratteri e si ferma quando incontra 'char' (' o ")

(defun parse-anychars (input char)
  (cond
   ((char= (first input) #\\)
    (multiple-value-bind (anychars rest_anychars)
        (parse-anychars (subseq input 2) char)
      (values (append (subseq input 1 2) anychars) rest_anychars)))
   ((not (char= (first input) char))
    (multiple-value-bind (anychars rest_anychars)
        (parse-anychars (rest input) char)
      (values (cons (first input) anychars) rest_anychars)))
   ((char= (first input) char) (values NIL (rest input)))
   ))



;parse-identifier
;Return: "string" - Rest
;La stringa puo' contenere solo lettere e numeri e inizia con una lettera

(defun parse-identifier (input) 
  (if (or (is-char (first input)) (is-digit (first input)))
      (multiple-value-bind (id rest_id) 
          (parse-identifier (rest input))
        (values (cons (first input) id) rest_id))
    (values NIL input)
    ))



;parse-number
;Return: Number - Rest

(defun parse-number (input)
  (multiple-value-bind (index dot)
      (get-number-index input)
    (cond
     (dot
      (values (parse-float (coerce (subseq input 0 index) 'string))
              (subseq input index)))
     ((not dot)
      (values (parse-integer (coerce (subseq input 0 index) 'string))
              (subseq input index)))
     (T (error "Syntax error. Rest string: ~S" input))
     )))



; FUNZIONI JSONWRITE

;jsonwrite
;Return: scrive un oggetto JSON nella corretta sintassi nel file fileName

(defun jsonwrite (object fileName)
  (with-open-file (out fileName
                       :direction :output
                       :if-exists :supersede
                       :if-does-not-exist :create)
    (write-json object out) (write-string fileName)))



;write-json

(defun write-json (object out)
  (cond
   ((null object) (error "object is NIL"))
   ((not (listp object)) (error "object is not a list"))
   ((equal (first object) 'jsonobj) (write-object object out))
   ((equal (first object) 'jsonarray) (write-array object out))
   (T (error "object is neither a jsonboj or a jsonarray"))
   ))



;write-object

(defun write-object (object out)
  (write-string "{" out)
  (write-members (rest object) out)
  (write-string "}" out)
  )



;write-members

(defun write-members (pairs out)
  (cond
   ((null pairs) NIL)
   ((null (second pairs)) (write-pair (first pairs) out))
   (T (progn
        (write-pair (first pairs) out)
        (write-string ", " out)
        (write-members (rest pairs) out)))
   ))



;write-pair

(defun write-pair (pair out)
  (write-strings (first pair) out)
  (write-string " : " out)
  (write-value (second pair) out)
  )



;write-array

(defun write-array (array out)
  (write-string "[" out)
  (write-elements (rest array) out)
  (write-string "]" out)
  )



;write-elements

(defun write-elements (array out)
  (cond
   ((null array) NIL)
   ((null (second array)) (write-value (first array) out))
   (T (progn
        (write-value (first array) out)
        (write-string ", " out)
        (write-elements (rest array) out)))
   ))



;write-value

(defun write-value (value out)
  (cond
   ((is-jsonobj value) (write-object value out))
   ((is-jsonarray value) (write-array value out))
   ((or (stringp value) (null value)) (write-strings value out))
   ((numberp value) (format out "~A" value))
   (T (error "~S is not a value" value))
   ))



;write-strings

(defun write-strings (string out)
  (if (null string)
      (write-string "\"\"" out)
    (progn (write-char #\" out)
      (loop for i across string do
            (if (or (char= i #\") (char= i #\\))
                (progn
                  (write-char #\\ out)
                  (write-char i out))
              (write-char i out)))
      (write-char #\" out))
    ))



; FUNZIONI UTILITIES

;remove-spaces
;Return: la lista in input senza 'spazi' all'inizio e alla fine della lista
;Optional: rimuove il carattere char se ÃƒÂ¨ in prima posizione, se no NIL

(defun remove-spaces (list &optional (char NIL))
  (cond
   ((null list) NIL)
   ((is-space (first list))
    (remove-spaces (rest list) char))
   ((is-space (first (last list)))
    (remove-spaces (butlast list) char))
   (T (cond
       ((equal (first list) char) (rest list))
       ((null char) list)
       (T NIL)
       ))))



;is-char
;Return: true if 'a' <= char <= 'z', else NIL

(defun is-char (char)
  (if (or (and (char>= char #\a) (char<= char #\z))
          (and (char>= char #\A) (char<= char #\Z)))
      T
    NIL
    ))



;is-digit
;Return: true if '0' <= digit <= '9', else NIL

(defun is-digit (digit)
  (if (and (char>= digit #\0) (char<= digit #\9))
      T
    NIL
    ))



;is-object
;Return: true if (equal (first object) #\{), else NIL
        
(defun is-object (object) 
  (cond
   ((null object) (error "Syntax error. Rest string: ~S" object))
   ((char= (first object) #\{) T)
   (T NIL)
   ))



;is-array
;Return: true if (equal (first input) #\[), else NIL

(defun is-array (array)
  (cond
   ((null array) (error "Syntax error. Rest string: ~S" array))
   ((char= (first array) #\[) T)
   (T NIL)
   ))



;is-space
;Return: T if #\space #\Tab #\Newline, else NIL

(defun is-space (char)
  (cond 
   ((char= char #\Space) T)
	 ((char= char #\Newline) T)
	 ((char= char #\Tab) T)
   (T NIL)
   ))



;is-jsonobj
;Return: true if input is '(jsonobj ..)

(defun is-jsonobj (input)
  (cond
   ((null input) NIL)
   ((not (listp input)) NIL)
   ((equal (first input) 'jsonobj) T)
   (T NIL)
   ))



;is-jsonarray
;Return: true if input is '(jsonarray ..)

(defun is-jsonarray (input)
  (cond
   ((null input) NIL)
   ((not (listp input)) NIL)
   ((equal (first input) 'jsonarray) T)
   (T NIL)
   ))



;get-number-index
;Return: l'indice della lista dell'ultima cifra a partire dall'indice 0
;Optional: se dot vale NIL "cerca" un float, se dot vale T cerca un intero

(defun get-number-index (list &optional (dot NIL))
  (cond
   ((null list) (values 0 NIL))
   ((is-digit (first list))
    (multiple-value-bind (index found_dot)
        (get-number-index (rest list) dot)
      (values (1+ index) found_dot)))
   ((and (char= (first list) #\.) (not dot) 
         (> (length list) 1) (is-digit (second list)))
    (values (1+ (get-number-index (rest list) T)) T))
   (T
    (values 0 dot))
   ))



;remove-occurrences
;Return: la lista in cui tutte le chiavi duplicate sono cancellate
;        viene mantenuta solo l'ultima Pair trovata

(defun remove-occurrences (object)
  (if (null object)
      NIL
    (cons (first object)
          (delete-pairs (first object) (remove-occurrences (rest object))))
    ))



;delete-pairs
;Return: la lista senza pair con la stessa chiave di 'pair'

(defun delete-pairs (pair list)
  (if (null list)
      NIL
    (cond
     ((equal (first (first list)) (first pair))
      (delete-pairs pair (rest list)))
     (T
      (cons (first list) (delete-pairs pair (rest list))))
     )))



;get-value
;Return: il valore associato alla key

(defun get-value (key pairs)
  (cond
   ((null pairs) (error "~S is undefined" key))
   ((string-equal (first (first pairs)) key) (second (first pairs)))
   (T (get-value key (rest pairs)))
   ))



;get-string-from-file
;Return: la stringa di testo contenuta nel file fileName

(defun get-strings-from-file (fileName)
  (with-open-file (stream fileName)
    (loop for line = (read-line stream nil)
          while line
          collect line)))



;concatenate-strings
;Return: la stringa ottenuta concatenando le stringhe presenti in lista

(defun concatenate-strings (lista)
  (unless (null lista)
    (concatenate 'string
                 (first lista)
                 (concatenate-strings (rest lista))
                 )))
