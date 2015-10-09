defmodule Mix.Dota do

  def save_img({:ok, img}, path, name) do
    file_path = Path.join(path, name <> "_lg.png")
    Task.async(fn -> File.write(file_path, img) end)
  end

  def save_img({:ok, img, size}, path, name) do
    file_path = Path.join(path, "#{name}_#{size}")
    Task.async(fn -> File.write(file_path, img) end)
  end

end