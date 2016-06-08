require Map

defmodule Emisor do

  def start(irc) do
    spawn_link(fn -> loop(irc) end)
  end

  def loop(irc) do
    receive do
        {:start_writting} ->
            send irc, {self, :start_writting}

        {:send, message} ->
            send irc, {self, :send, message}

        {pid, :recieved, message} ->
            IO.puts 'Se ha recibido el mensaje "#{message}" de #{inspect pid}'

        {pid, _ } ->
            send :pid, {:error, 'Accion Invalida de #{inspect pid}'}
    end
    loop(irc)
  end

end


defmodule IRC do
    def start do
        spawn_link(fn -> loop([], %{}) end)
    end

    def loop(subscribed, silenced) do
        receive do
            {pid, :subscribe} ->
                IO.puts "Se ha subscribido: #{inspect pid}"
                loop [ pid | subscribed ], silenced

            {pid, :silence, receptor} ->
                if Map.get(silenced, pid),
                    do: loop(subscribed, Map.update!(silenced, pid, fn list -> [ receptor | list ] end)),
                    else: loop(subscribed, Map.put(silenced, pid, [receptor]))

            {pid, :start_writting} ->
                IO.puts "El emisor #{inspect pid} ha empezado a escribir"
                for subscriber <- subscribed do
                    send subscriber, {pid, :start_writting}
                end
                loop subscribed, silenced


            {pid, :send, message} ->
                IO.puts "El emisor #{inspect pid} ha enviado #{message}"
                for subscriber <- subscribed do
                    send subscriber, {pid, :message, message}
                end
                loop subscribed, silenced

            {pid, :recieved, emisor, message} ->
                send(emisor, {pid, :recieved, message})
                if (pid in Map.get(silenced, emisor)),
                    do: IO.puts "Silenced receptor: #{inspect pid} for emisor #{inspect emisor}",
                    else: IO.puts "hasdasd"
                loop subscribed, silenced

            {pid, _ } ->
                send pid, {:error, 'Accion Invalida de #{inspect pid}'}
                loop subscribed, silenced
        end
    end
end

defmodule Receptor do
  def start(irc) do
    spawn_link(fn ->
        loop(irc)
    end)
  end

  def loop(irc) do
    receive do
        {pid, :start_writting} ->
            IO.puts "Receptor #{inspect self} Ha empezado a escribir el mensaje el usuario: #{inspect pid}"

        {pid, :message, message} ->
            IO.puts 'Receptor #{inspect self} Emisor #{inspect pid}: #{message}'
            send irc, {self, :recieved, pid, message}

        {pid, _ } ->
            send :pid, {:error, 'Accion Invalida de #{inspect pid}'}
    end
    loop(irc)
  end

end

irc = IRC.start
Process.register irc, :irc
IO.puts "IRC: #{inspect irc}"

receptor1 = Receptor.start(:irc)
receptor2 = Receptor.start(:irc)
receptor3 = Receptor.start(:irc)

emisor = Emisor.start(:irc)

Process.register emisor, :emisor
Process.register receptor1, :receptor1
Process.register receptor2, :receptor2
Process.register receptor3, :receptor3

IO.puts "Receptor 1: #{inspect receptor1}"
IO.puts "Receptor 2: #{inspect receptor2}"
IO.puts "Receptor 3: #{inspect receptor3}"

send :irc, {:receptor1, :subscribe}
send :irc, {:receptor2, :subscribe}
send :irc, {:receptor3, :subscribe}

send :irc, {:emisor, :start_writting}
send :irc, {:emisor, :send, "Hola"}

send :irc, {:emisor, :silence, :receptor2}

send :irc, {:emisor, :send, "Chau"}