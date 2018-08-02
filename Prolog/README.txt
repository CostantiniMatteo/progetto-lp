Matteo Colella - 794028
Matteo Angelo Costantini - 795125
Dario Gerosa - 793636

Il programma è stato definito usando le DCG, dopo averle comprese e studiate, sia per jsonparse/2 che per jsonwrite/2.
Il funzionamento di jsonparse/2 è molto semplice e segue la grammatica imposta dal pdf del progetto.
Il predicato remove_occurrences/2 fa in modo che nell'oggetto JSON creato, ogni chiave compaia una sola volta, mantenendo, in caso di occorrenze multiple, solamente l'ultimo valore associato.
Il predicato jsonload/2 esegue direttamente il parsing della stringa contenuta nel file, senza bisogno di ulteriore chiamata di jsonparse/2.
Il predicato jsonwrite/2 tramite la stessa grammatica di jsonparse/2 (con alcune modifiche a causa della non invertibilità delle prime produzioni dovute ai controlli sui caratteri e ai whitespace) e tramite il predicato phrase/2, ricrea la lista di codici da cui deriva l'oggetto JSON da riscrivere, crea un atomo a partire dalla lista di codici e lo scrive sul file specificato.
Per quanto riguarda il jsonget/3, abbiamo diversificato il caso in cui i campi passati come parametri sono racchiusi in una lista dal caso in cui il campo passato è solo un atomo avvalendoci della funzione jsonget_aux/3.

NOTA:
A causa di dubbi riguardanti la grammatica modificata json abbiamo deciso di gestire nel seguente modo il parsing delle stringhe:
1 - Se nella stringa è presente un carattere di backslash il carattere successivo viene parsato senza essere analizzato e il parsing della stringa continua.
    Esempio: "questa è \una \stringa" -> "questa è una stringa"

2 - Se la stringa è delimitata da doppi apici, un doppio apice all'interno della stringa deve necessariamente essere preceduto da un backslash (come previsto da 1)
    Esempio: "stringa\"stringa" -> "stringa"stringa"
             "stringa"stringa" -> fail

3- Se la stringa è delimitata da apici singoli, un apice singolo all'interno della stringa deve necessariamente essere preceduto da un backslash (come previsto da 1)