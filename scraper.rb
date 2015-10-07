#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'
require 'wikidata'
require 'active_support/core_ext/integer/inflections'


require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

areas = { 
  'Capital' => 'محافظة العاصمة',
  'Muharraq' => 'محافظة المحرق',
  'Northern' => 'المحافظة الشمالية',
  'Southern' => 'المحافظة الجنوبية',
}

noko = noko_for('https://ar.wikipedia.org/wiki/%D8%A7%D9%84%D8%A7%D9%86%D8%AA%D8%AE%D8%A7%D8%A8%D8%A7%D8%AA_%D8%A7%D9%84%D9%86%D9%8A%D8%A7%D8%A8%D9%8A%D8%A9_%D9%88%D8%A7%D9%84%D8%A8%D9%84%D8%AF%D9%8A%D8%A9_%D8%A7%D9%84%D8%A8%D8%AD%D8%B1%D9%8A%D9%86%D9%8A%D8%A9_2014')

areas.each do |en, ar|
  h3 = noko.xpath('//h3[contains(.,"%s")]' % ar).first 
  tables = h3.xpath('following-sibling::h2 | following-sibling::h3 | following-sibling::table').slice_before { |e| e.name != 'table' }.first
  tables.each_with_index do |t, i|
    winner = t.xpath('.//tr[td[b]]')
    binding.pry unless winner.count == 1
    tds = winner.css('td')
    data = { 
      name__ar: tds[0].css('a').text.tidy,
      wikiname: tds[0].xpath('.//a[not(@class="new")]/@title').text,
      area: "%s %s" % [(i+1).ordinalize, en],
      area__ar: "%s: %s" % [ar, t.css('caption').text.split(':').first.tidy],
      term: 2014
    }
    ScraperWiki.save_sqlite([:area, :term, :name__ar], data)
  end
end

    
