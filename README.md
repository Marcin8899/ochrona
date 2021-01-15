# Projekt ochrona danych

Aplikacja korzysta z bazy danych MySQL.

Hasło jest hashowane 10-krotnie za pomocą algorytmu sha256.

Notatki są szyfrowane za pomocą algorytmu ARC4.

Kod do zmiany hasła, który docelowo przychodzi na maila i jest oczywiście unikaly: mail123

Przy pierwszym uruchomieniu aplikacji może pojawić się błąd informujący o odrzuceniu połączenia z bazą danych, 
należy wtedy odświeżyć aplikację i powinna działać.

Istnieją 3 konta pułapki: admin, root, master, na które nie da się zalogować (błędne hashe), a każda próba logowania jest
rejestrowana i widocza w logach.

Po 10 nieudanych próbach adres IP jest blokowany.

Przy każdym logowaniu dodawane są 2 sekundy opóźnienia.

Przy rejestracji wyspępuje symulacja zabezpieczenia captcha - wyświetlana jest całka do obliczenia, co jest wymogiem zarejestrowania (jako symulacja jest ciągle ta sama).

Przy błędnej rejestracji wyskakuje komunikat błędne dane w sytuacji gdy: 
- użytkownik jest zajęty
- e-mail jest zajęty
- błędnie obliczona całka
Aby nie dawać informacji np. o tym czy taki użytkownik istnieje, komunikat nie precyzuje co dokładnie jest źle.

Aby użytkownik mógł cokolwiek zrobić wymagana jest sesja w bazie danych, poporawny żeton jtw oraz poprawna sesja Flask-a.