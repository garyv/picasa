require "net/http"
require "xmlsimple"

module Picasa
  class WebAlbums
    def initialize(user)
      Picasa.config.google_user = user if user
      raise ArgumentError.new("You must specify google_user") unless Picasa.config.google_user
    end

    def albums(options = {})
      data = connect("/data/feed/api/user/#{Picasa.config.google_user}", options)
      xml = XmlSimple.xml_in(data)
      albums = []
      xml["entry"].each do |album|
        attributes = {}
        attributes[:id] = album["id"][1]
        attributes[:title] = album["title"][0]["content"]
        attributes[:summary] = album["summary"][0]["content"]
        attributes[:photos_count] = album["numphotos"][0].to_i
        attributes[:photo] = album["group"][0]["content"]["url"]
        attributes[:thumbnail] = album["group"][0]["thumbnail"][0]["url"]
        attributes[:slideshow] = album["link"][1]["href"] + "#slideshow"
        attributes[:updated] = album["updated"][0]
        attributes[:url] = album["link"][1]["href"]
        albums << attributes
      end if xml["entry"]
      albums
    end

    def photos(album_id, options = {})
      data = connect("/data/feed/api/user/#{Picasa.config.google_user}/albumid/#{album_id}", options)
      xml = XmlSimple.xml_in(data)
      photos = []
      xml["entry"].each do |photo|
        attributes = {}
        attributes[:id] = photo["id"][1]
        attributes[:title] = photo["group"][0]["description"][0]["content"]
        attributes[:thumbnail_1] = photo["group"][0]["thumbnail"][0]["url"]
        attributes[:thumbnail_2] = photo["group"][0]["thumbnail"][1]["url"]
        attributes[:thumbnail_3] = photo["group"][0]["thumbnail"][2]["url"]
        attributes[:photo] = photo["content"]["src"]
        attributes[:lat] = photo["where"][0]["Point"][0]["pos"][0][/^\S*/]
        attributes[:long] = photo["where"][0]["Point"][0]["pos"][0][/\S*$/]
        photos << attributes
      end if xml["entry"]
      {:photos => photos, :slideshow => xml["link"][1]["href"] + "#slideshow"}
    end

    private

    def connect(url, options = {})
      full_url = "http://picasaweb.google.com" + url
      full_url += "?" + URI.encode_www_form(options) unless options.empty?
      Net::HTTP.get(URI.parse(full_url))
    end
  end
end
