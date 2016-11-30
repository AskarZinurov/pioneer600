module Pioneer600::Ssd1306
  module Font
    def pages
      (size[1] / Area::PAGE_SIZE.to_f).ceil
    end

    def columns
      size[0]
    end

    def write_to(area, text)
      char_bytes = text.split(//).map { |ch| encode(ch) }
      total_columns = columns * char_bytes.size
      visible_columns = area.columns < total_columns ? area.columns : total_columns
      visible_pages(area).times do |ri|
        char_bytes.each_with_index do |ch, i|
          ch_row = ch.slice(ri*columns, columns)
          ch_row.each_with_index do |b, ci|
            break if i*columns + ci > visible_columns
            area[i*columns + ci][ri] = b
          end
        end
      end
    end

    private

    def visible_pages(area)
      area.pages < pages ? area.pages : pages
    end
  end
end
