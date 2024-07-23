defmodule Library do
  defmodule Book do
    defstruct title: "", author: "", isbn: "", available: true
  end

  defmodule User do
    defstruct name: "", id: "", borrowed_books: []
  end

  def add_book(library, %Book{} = book) do
    library ++ [book]
  end

  def add_user(users, %User{} = user) do
    users ++ [user]
  end

  def borrow_book(library, users, user_id, isbn) do
    user = Enum.find(users, &(&1.id == user_id))
    book = Enum.find(library, &(&1.isbn == isbn && &1.available))
    # Vamos a modificar el cond do para que
    cond do
      user == nil -> {:error, "Usuario no encontrado"}
      book == nil -> {:error, "Libro no disponible"}

      true ->
        updated_book = %{book | available: false}
        updated_user = %{user | borrowed_books: user.borrowed_books ++ [updated_book]}

        updated_library =
          Enum.map(library, fn
            b when b.isbn == isbn -> updated_book
            b -> b
          end)

        updated_users =
          Enum.map(users, fn
            u when u.id == user_id -> updated_user
            u -> u
          end)

        {:ok, updated_library, updated_users}
    end
  end

  def return_book(library, users, user_id, isbn) do
    user = Enum.find(users, &(&1.id == user_id))
    book = Enum.find(user.borrowed_books, &(&1.isbn == isbn))

    cond do
      user == nil -> {:error, "Usuario no encontrado"}
      book == nil -> {:error, "Libro no encontrado en los libros prestados del usuario"}

      true ->
        updated_book = %{book | available: true}

        updated_user = %{
          user
          | borrowed_books: Enum.filter(user.borrowed_books, &(&1.isbn != isbn))
        }

        updated_library =
          Enum.map(library, fn
            b when b.isbn == isbn -> updated_book
            b -> b
          end)

        updated_users =
          Enum.map(users, fn
            u when u.id == user_id -> updated_user
            u -> u
          end)

        {:ok, updated_library, updated_users}
    end
  end

  def list_books(library) do
    library
  end

  def list_users(users) do
    users
  end

  def books_borrowed_by_user(users, user_id) do
    user = Enum.find(users, &(&1.id == user_id))
    if user, do: user.borrowed_books, else: []
  end

  # Nuevas Funcionalidades:
  # Buscando libros por ISBN:
  def find_book_by_isbn(library, isbn) do
    Enum.find(library, &(&1.isbn == isbn))
  end

  # Eliminando libros de la libreria
  def delete_book(library, isbn) do
    updated_library = Enum.filter(library, &(&1.isbn != isbn))
    deleted_book = Enum.find(library, &(&1.isbn == isbn))
    {updated_library, deleted_book}
  end

  # Eliminando usuario:
  def delete_user(users, user_id) do
    updated_users = Enum.filter(users, &(&1.id != user_id))
    deleted_user = Enum.find(users, &(&1.id == user_id))
    {updated_users, deleted_user}
  end

  def run do
    library = []
    users = []
    loop(library, users)
  end

  defp loop(library, users) do
    IO.puts("""
    Gestión de Libreria
    1. Agregar un nuevo libro
    2. Listar libros disponibles
    3. Disponibilidad del libro por ISBN
    4. Registrar nuevo usuario
    5. Listar usuarios registrados
    6. Pedir prestado un libro
    7. Devolver un libro prestado
    8. Listar libros prestados a un usuario
    9. Eliminar un libro
    10. Eliminar un usuario
    11. Buscar libro por ISBN
    12. Salir
    """)

    IO.write("Seleccione una opción: ")
    option = IO.gets("") |> String.trim() |> String.to_integer()

    # En lugar de usar case, vamos a usar cond/do
    cond do
      option == 1 ->
        title = IO.gets("Título del libro: ") |> String.trim()
        author = IO.gets("Autor del libro: ") |> String.trim()
        isbn = IO.gets("ISBN del libro: ") |> String.trim()
        book = %Book{title: title, author: author, isbn: isbn}
        loop(add_book(library, book), users)

      option == 2 ->
        IO.puts("Libros disponibles:")

        Enum.each(list_books(library), fn book ->
          IO.puts(
            "Título: #{book.title}, Autor: #{book.author}, ISBN: #{book.isbn}, Disponible: #{book.available}"
          )
        end)

        loop(library, users)

      option == 3 ->
        isbn = IO.gets("ISBN del libro: ") |> String.trim()
        available = Enum.any?(library, &(&1.isbn == isbn && &1.available))
        IO.puts(if available, do: "El libro está disponible", else: "El libro no está disponible")
        loop(library, users)

      option == 4 ->
        name = IO.gets("Nombre del usuario: ") |> String.trim()
        id = IO.gets("ID del usuario: ") |> String.trim()
        user = %User{name: name, id: id}
        loop(library, add_user(users, user))

      option == 5 ->
        IO.puts("Usuarios registrados:")

        Enum.each(list_users(users), fn user ->
          IO.puts("Nombre: #{user.name}, ID: #{user.id}")
        end)

        loop(library, users)

      option == 6 ->
        user_id = IO.gets("ID del usuario: ") |> String.trim()
        isbn = IO.gets("ISBN del libro: ") |> String.trim()

        case borrow_book(library, users, user_id, isbn) do
          {:ok, new_library, new_users} ->
            loop(new_library, new_users)

          {:error, message} ->
            IO.puts(message)
            loop(library, users)
        end

      option == 7 ->
        user_id = IO.gets("ID del usuario: ") |> String.trim()
        isbn = IO.gets("ISBN del libro: ") |> String.trim()

        case return_book(library, users, user_id, isbn) do
          {:ok, new_library, new_users} ->
            loop(new_library, new_users)

          {:error, message} ->
            IO.puts(message)
            loop(library, users)
        end

      option == 8 ->
        user_id = IO.gets("ID del usuario: ") |> String.trim()
        books = books_borrowed_by_user(users, user_id)
        IO.puts("Libros prestados al usuario #{user_id}:")

        Enum.each(books, fn book ->
          IO.puts("Título: #{book.title}, Autor: #{book.author}, ISBN: #{book.isbn}")
        end)

        loop(library, users)

      option == 9 ->
        isbn = IO.gets("ISBN del libro a eliminar: ") |> String.trim()
        {updated_library, deleted_book} = delete_book(library, isbn)

        IO.puts(
          if deleted_book,
            do:
              "Libro eliminado: Título: #{deleted_book.title}, Autor: #{deleted_book.author}, ISBN: #{deleted_book.isbn}",
            else: "Libro no encontrado"
        )

        loop(updated_library, users)

      option == 10 ->
        user_id = IO.gets("ID del usuario a eliminar: ") |> String.trim()
        {updated_users, deleted_user} = delete_user(users, user_id)

        IO.puts(
          if deleted_user,
            do: "Usuario eliminado: Nombre: #{deleted_user.name}, ID: #{deleted_user.id}",
            else: "Usuario no encontrado"
        )

        loop(library, updated_users)

      option == 11 ->
        isbn = IO.gets("ISBN del libro a buscar: ") |> String.trim()
        book = find_book_by_isbn(library, isbn)

        IO.puts(
          if book,
            do:
              "Libro encontrado: Título: #{book.title}, Autor: #{book.author}, ISBN: #{book.isbn}, Disponible: #{book.available}",
            else: "Libro no encontrado"
        )

        loop(library, users)

      option == 12 ->
        IO.puts("Adiós!")
        :ok

      true ->
        IO.puts("Opción no válida")
        loop(library, users)
    end
  end
end

# Ejecutar el gestor de tareas
Library.run()
