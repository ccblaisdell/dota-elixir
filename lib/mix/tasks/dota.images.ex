defmodule Mix.Tasks.Dota.Images do

  def run(args) do
    Task.async(fn -> Mix.Tasks.Dota.Images.Heroes.run(args) end)
    Task.async(fn -> Mix.Tasks.Dota.Images.Items.run(args) end)
  end

  defmodule Heroes do
    
    def run(args) do
      path = "web/static/assets/images/heroes"
      case File.mkdir_p(path) do
        :ok ->
          Dota.Hero.all
          |> Enum.each(&save_hero_imgs(&1, path))
        _ -> 
          {:error, "Path could not be created"}
      end
    end

    defp save_hero_imgs({id, %{"name" => name}}, path) do
      Dota.hero_img(id)
      |> Enum.each(&Mix.Dota.save_img(&1, path, name))
    end

  end


  defmodule Items do

    def run(args) do
      path = "web/static/assets/images/items"
      case File.mkdir_p(path) do
        :ok ->
          Dota.Item.all
          |> Enum.each(&save_item_imgs(&1, path))
        _ -> 
          {:error, "Path could not be created"}
      end
    end

    defp save_item_imgs({id, %{"name" => name}}, path) do
      Dota.item_img(id)
      |> Mix.Dota.save_img(path, name)
    end

  end
  
end