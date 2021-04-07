require 'stringio'

module MusicEdo
  class << self
    EDO_INTERVAL_NAMES = {
      12 => {
        0 =>  :unison,
        1 =>  :minor_second,
        2 =>  :major_second,
        3 =>  :minor_third,
        4 =>  :major_third,
        5 =>  :perfect_fourth,
        6 =>  :tritone,
        7 =>  :perfect_fifth,
        8 =>  :minor_sixth,
        9 =>  :major_sixth,
        10 => :minor_seventh,
        11 => :major_seventh
      }
    }

    ABBREV_INTERVAL_NAMES = {
      12 => {
        unison:         'P1',
        minor_second:   'm2',
        major_second:   'M2',
        minor_third:    'm3',
        major_third:    'M3',
        perfect_fourth: 'P4',
        tritone:        'd5',
        perfect_fifth:  'P5',
        minor_sixth:    'm6',
        major_sixth:    'M6',
        minor_seventh:  'm7',
        major_seventh:  'M7'
      }
    }

    def _12edo_ratios
      @_12edo_ratios ||= generate_edo_ratios(12)
    end

    def _12edo_interval_name_from_interval_number(interval_number)
      EDO_INTERVAL_NAMES.dig(12, interval_number)
    end

    def _12edo_abbrev_interval_name_from_interval_number(interval_number)
      full_name = _12edo_interval_name_from_interval_number(interval_number)
      ABBREV_INTERVAL_NAMES.dig(12, full_name)
    end

    def find_closest_12edo_interval_number(input_ratio)
      _12edo_ratios.transform_values do |ratio|
        case ratio
        when 1
          # A big number so it never matches unison
          1_000_000
        else
          difference = (input_ratio - ratio).abs
          difference
        end
      end.min do |(interval_number_a, difference_a), (interval_number_b, difference_b)|
        difference_a <=> difference_b
      end&.[](0)
    end

    def generate_edo_ratios(number_of_tones)
      Hash[
        number_of_tones.times.map do |n|
          ratio = 2**(n/number_of_tones.to_f)
          [n, ratio]
        end
      ]
    end

    def compare_edo_ratios_with_12edo(edo_ratios, within: 0.01)
      StringIO.new.tap do |s|
        # Generate Header Row
        s.puts('-'*80)

        header_printf_string = ""
        header_printf_args = []

        edo_ratios.size.times do |interval_number|
          next if interval_number.zero?

          header_printf_string << "%-12s|"
          header_printf_args << interval_number
        end
        header_printf_string << "\n"

        s.printf(header_printf_string, *header_printf_args)

        # Generate Data Row
        edo_ratios.each do |interval_number, ratio|
          next if interval_number.zero?

          closest_12edo_interval_number = find_closest_12edo_interval_number(ratio)
          closest_12edo_abbrev_interval_name   = _12edo_abbrev_interval_name_from_interval_number(closest_12edo_interval_number)

          difference = ratio - _12edo_ratios[closest_12edo_interval_number]
          abs_difference = difference.abs

          if abs_difference < within
            color_number = 32
          else
            color_number = 31
          end

          data_string = "#{closest_12edo_abbrev_interval_name} #{difference.round(5)}"

          s.printf("%-12s|", data_string)
        end
      end.string
    end
  end
end

(5..17).each do |n|
  puts MusicEdo.compare_edo_ratios_with_12edo(MusicEdo.generate_edo_ratios(n))
end
