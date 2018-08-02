Matteo Colella - 794028
Matteo Angelo Costantini - 795125
Dario Gerosa - 793636



Il parser è stato implementato principalmente sfruttando le funzioni multiple-value-bind e values di lisp che ci ha permesso di far restituire alle funzioni di parsing due valori: il primo, l'oggetto parziale che è stato parsato dalla funzione; il secondo, il resto della stringa che ancora non è stata parsata.

La funzione jsonparse inizia la "catena" di chiamate ricorsive delle funzioni di parsing.

La funzione jsonwrite crea uno stream associato al file specificato e richiama ricorsivamente le funzioni di 'write' che permettono di stampare l'oggetto json.

La funzione jsonget accetta un numero arbitrario di field e richiama subito una funzione ausiliaria che raccoglie tutti i field in una lista per permettere una gestione della funzione in modo ricorsivo e meno macchinoso.
La funzione jsonload richiama la funzione jsonparse dopo aver creato un unica stringa a partire dal file.
Il file è stato letto linea per linea e poi le varie stringhe ottenute sono state concatenate, la stringa ottenuta dalla concatenazione è l'argomento della funzione jsonparse.



NOTA:

A causa di dubbi riguardanti la grammatica modificata json abbiamo deciso di gestire nel seguente modo il parsing delle stringhe:

1 - Se nella stringa è presente un carattere di backslash il carattere successivo viene parsato senza essere analizzato e il parsing della stringa continua.

    Esempio: "questa è \una \stringa" -> "questa è una stringa"



2 - Se la stringa è delimitata da doppi apici, un doppio apice all'interno della stringa deve necessariamente essere preceduto da un backslash (come previsto da 1)

    Esempio: "stringa\"stringa" -> "stringa"stringa"

             "stringa"stringa" -> error



3- Se la stringa è delimitata da apici singoli, un apice singolo all'interno della stringa deve necessariamente essere preceduto da un backslash (come previsto da 1)