require 'rubygems'
require 'net/http'
require 'uri'
require 'hpricot'

module SalaProf
  class Info
    DOMINIO = "http://img.limao.com.br/audios/" #B6/B4/E8//B6B4E885613E46D69AC80638986B6DB5.mp3
    EXT = ".mp3"

    def initialize(pag=1)
      @pag = pag
      @url = "http://int.territorioeldorado.limao.com.br/eldorado/audios!getAudios.action?idPrograma=67&p="+@pag.to_s
      @html = Net::HTTP.get(URI.parse(@url))

      return false if not self.pag_existente?

      doc = Hpricot(@html)
      File.open("#{@pag.to_s}_SalaProf.txt", 'w') do |f|
        doc.search("//div[@class='lista']/ul/li").each_with_index do |li, index|
          h4 = li.search("//h4/a").first

          # ID do Programa
          id = h4.attributes['href'].split('=')[1]
          link = SalaProf::Info.montar_link_mp3 id
          f.puts link
          Download.wget(link)

          # Titulo
          titulo = h4.inner_html.split(';').first
          f.puts titulo
          # Renomeia o arquivo
          Download.mv(id+EXT, @pag.to_s+'_'+index.to_s+'-'+titulo.higienize+EXT)

          # Descrição
          p = li.search("//p/a").first
          f.puts p.inner_html

          f.puts "\n"
        end
      end
    end #initialize

    # Quebra os seis primeiros caracteres; agrupa em duplas; e monta o padrão de diretorio XX/XX/XX
    def self.montar_link_mp3(id)
      dir = id[0..5].split(//).each_slice(2).inject([]){|ac, i| ac << i.to_s}
      DOMINIO + dir.join('/') + '/' + id + EXT
    end

    def pag_existente?
      erro = "Ocorreu um erro inesperado"
      if @html.include?(erro)
        return false
      end
      return true
    end
  end #Info

  class Download
    def initialize(link)
      @link = link
    end

    def wget
      system "wget #{@link}"
    end

    class << self
      def wget(p_link)
        Download.new(p_link).wget
      end

      def renomear_arquivos
        #Dir.foreach(".") do |f, index|
        Dir.glob('*.mp3').each_with_index do |value, index|
          #unless m = (f.match(/[A-Z|0-9]*\.mp3/)).nil?
            File.rename(value.to_s, "#{index.to_s}-#{value.to_s}")
          #end
        end
      end

      def mv(name, new_name)
        File.rename(name.to_s, new_name)
      end
    end #self
  end #Download

end #module

# OverWrite
class String
  NOT_INCLUDE = ["no sala", "do sala", "Sala dedica", "Sala traz", "SALA explica", "SALA destaca", "são destaque no SALA", "é destaque no SALA"]
  def higienize
    titulo = self.clone
    NOT_INCLUDE.each{|termo| titulo.gsub!(termo, '')}
    return titulo.strip.capitalize.gsub('"','').gsub("'", '')
  end
end