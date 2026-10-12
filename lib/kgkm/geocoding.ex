defmodule Kgkm.GeoCoding do
  @moduledoc """
  Converte latitude e longitude em um nome legivel de cidade/estado
  """
  def get_city_name(lat, lng) do
    url = "https://nominatim.openstreetmap.org/reverse"
    headers = [{"user-agent", "PetHub/1.0"}]
    params = [lat: lat, lon: lng, format: "json", "accept-language": "pt-BR,pt;q=0.9,en;q=0.8"]

    case Req.get(url, headers: headers, params: params) do
      {:ok, %Req.Response{status: 200, body: %{"address" => address}}} ->
        city =
          address["city"] || address["town"] || address["village"] || address["municipality"] ||
            address["suburb"]

        state = address["state"]

        if city && state do
          {:ok, "#{city} - #{state}"}
        else
          {:ok, city || state || "Unknown Location"}
        end

      _error ->
        {:error, "It was not possible to identify the city."}
    end
  end

  @doc """
  Busca cidades/endereços por texto (Autocomplete) usando OpenStreetMap Nominatim.
  """
  def search_locations(query) when is_binary(query) and byte_size(query) >= 3 do
    url = "https://nominatim.openstreetmap.org/search"
    headers = [{"user-agent", "AiyfApp/1.0"}]

    params = [
      q: query,
      format: "json",
      addressdetails: 1,
      limit: 5,
      "accept-language": "pt-BR,pt;q=0.9,en;q=0.8"
    ]

    case Req.get(url, headers: headers, params: params) do
      {:ok, %Req.Response{status: 200, body: items}} when is_list(items) ->
        results =
          Enum.map(items, fn item ->
            address = item["address"] || %{}

            city =
              address["city"] || address["town"] || address["village"] || address["municipality"]

            state = address["state"]

            display =
              if city && state do
                "#{city} - #{state}"
              else
                item["display_name"]
              end

            %{
              id: item["place_id"],
              display_name: display,
              full_name: item["display_name"]
            }
          end)
          |> Enum.uniq_by(& &1.display_name)

        {:ok, results}

      _ ->
        {:ok, []}
    end
  end

  def search_locations(_), do: {:ok, []}
end
