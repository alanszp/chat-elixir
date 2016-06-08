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

        {pid, :recieved, m_id} ->
            IO.puts 'Notificacion: Se ha recibido el mensaje #{m_id} de #{inspect pid}'

        {pid, :read, m_id} ->
            IO.puts 'Notificacion: El receptor #{inspect pid} ha leido el mensaje #{m_id}'

        {pid, _ } ->
            send :pid, {:error, 'Accion Invalida de #{inspect pid}'}
    end
    loop(irc)
  end

end


defmodule IRC do
    def start do
        spawn_link(fn -> loop([], %{}, %{}) end)
    end

    def loop(subscribed, silenced_sends, silenced_reads) do
        receive do
            {pid, :subscribe} ->
                IO.puts "Se ha subscribido: #{inspect pid}"
                loop [ pid | subscribed ], silenced_sends, silenced_reads

            {pid, :silence_read, receptor} ->
                IO.puts "El emisor #{inspect pid} no recibira las notificaciones de lectura de #{inspect receptor}"
                if Map.get(silenced_reads, pid) do
                    loop subscribed, silenced_sends, Map.update!(silenced_reads, pid, fn list -> [ receptor | list ] end)
                else
                    loop subscribed, silenced_sends, Map.put(silenced_reads, pid, [receptor])
                end

            {pid, :silence_send, emisor} ->
                IO.puts "El receptor #{inspect pid} no recibira los mensajes de #{inspect emisor}"

                if Map.get(silenced_sends, pid) do
                    loop subscribed, Map.update!(silenced_sends, emisor, fn list -> [ pid | list ] end), silenced_reads
                else
                    loop subscribed, Map.put(silenced_sends, emisor, [pid]), silenced_reads
                end

            {pid, :start_writting} ->
                IO.puts "El emisor #{inspect pid} ha empezado a escribir"
                receptors = Map.get(silenced_sends, pid) || []
                for subscriber <- subscribed, ! subscriber in receptors do
                    send subscriber, {pid, :start_writting}
                end
                loop subscribed, silenced_sends, silenced_reads


            {pid, :send, message} ->
                IO.puts "El emisor #{inspect pid} ha enviado #{inspect message}"
                receptors = Map.get(silenced_sends, pid) || []
                for subscriber <- subscribed, ! subscriber in receptors do
                    send subscriber, {pid, :message, message}
                end

                loop subscribed, silenced_sends, silenced_reads

            {pid, :recieved, emisor, message} ->
                receptors = Map.get(silenced_reads, emisor) || []
                
                unless pid in receptors do
                    send(emisor, {pid, :recieved, message})
                end

                loop subscribed, silenced_sends, silenced_reads

            {pid, :read, emisor, message} ->
                receptors = Map.get(silenced_reads, emisor) || []
                
                unless pid in receptors do
                    send(emisor, {pid, :read, message})
                end

                loop subscribed, silenced_sends, silenced_reads

            {pid, _ } ->
                send pid, {:error, 'Accion Invalida de #{inspect pid}'}
                loop subscribed, silenced_sends, silenced_reads
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
        {:read, emisor, m_id} ->
            IO.puts 'Receptor #{inspect self} ha leido el mensaje #{m_id}'
            send irc, {self, :read, emisor, m_id}

        {pid, :start_writting} ->
            IO.puts "Receptor #{inspect self} Ha empezado a escribir el mensaje el usuario: #{inspect pid}"

        {pid, :message, {m_id, message}} ->
            IO.puts 'Receptor #{inspect self} Emisor #{inspect pid}: #{message} (#{m_id})'
            send irc, {self, :recieved, pid, m_id}

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

IO.puts "Emisor: #{inspect emisor}"
IO.puts "Receptor 1: #{inspect receptor1}"
IO.puts "Receptor 2: #{inspect receptor2}"
IO.puts "Receptor 3: #{inspect receptor3}"

:timer.sleep(100)
IO.puts "\n---------------------------\n"

send :irc, {receptor1, :subscribe}
send :irc, {receptor2, :subscribe}
send :irc, {receptor3, :subscribe}

:timer.sleep(100)
IO.puts "\n---------------------------\n"

send :emisor, {:start_writting}
:timer.sleep(500)

send :emisor, {:send, {1, "Hola"}}
:timer.sleep(500)

IO.puts "\n---------------------------\n"

send :irc, {receptor1, :silence_send, emisor}
send :irc, {emisor, :silence_read, receptor3}

:timer.sleep(500)
IO.puts "\n---------------------------\n"

send :emisor, {:start_writting}
:timer.sleep(500)

send :emisor, {:send, {2, "Chau"}}

:timer.sleep(500)
IO.puts "\n---------------------------\n"

send :receptor1, {:read, emisor, 1}

:timer.sleep(500)
IO.puts "\n---------------------------\n"

