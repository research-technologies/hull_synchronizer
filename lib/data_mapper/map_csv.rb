module DataMapper
  class MapCSV
    require 'csv'

    attr_accessor :input_file, :output_file, :rows

    def initialize(file = nil,
      output_file_dir = 'tmp',
      output_file_name = "#{Time.now.strftime('%Y-%m-%d_%H-%M-%S-%L')}.csv")
      @input_file = file
      @output_file = File.join(output_file_dir, output_file_name)
      @rows = 0
    end

    def generate_file
      if File.exist?(@input_file)
        ::CSV.open(@output_file, "wb") do |output_csv|
          # Write the headers
          output_csv << header.values
          # read each row
          # ::CSV.foreach(@input_file, headers: true, header_converters: :symbol) do |row|
          ::CSV.foreach(@input_file, headers: true) do |row|
            # process it
            new_row = deep_copy(row)
            to_process.each do |attr, func|
              new_row[attr] = self.send(func.to_sym, row)
            end
            # write each row
            output_csv << header.keys.map{ |attr| new_row.fetch(attr, nil) }
          end
        end
      end
    end

    def deep_copy(o)
      Marshal.load(Marshal.dump(o))
    end

  end
end
