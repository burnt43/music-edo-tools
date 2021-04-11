require 'stringio'

class Integer
  # Find the closest power of 2 that is less then this Interger.
  # Ex:
  # 5.closest_lower_power_of_two = 4
  # 63.closest_lower_power_of_two = 32
  def closest_lower_power_of_two
    lower_exponent = Math.log(self, 2).floor
    2 ** lower_exponent
  end
end # Integer

module MusicEdo
  class Temperment
    class << self
      # Generate a temperement with equal division of the octave.
      # The argument is the amount of notes so:
      # generate_edo(15) will give you 15-edo
      def generate_edo(number_of_notes)
        divisions_f = number_of_notes.to_f

        degrees = number_of_notes.times.map do |n|
          ratio = 2 ** (n/divisions_f)
          MusicEdo::Degree.new(n, ratio)
        end

        new(degrees)
      end

      # Generate the harmonic series up to the (number_of_harmonics - 1)th
      # harmonic. The harmonic series can go on forever so we have to stop
      # it somewhere.
      def generate_harmonic_series(number_of_harmonics)
        degrees =
          number_of_harmonics.times.map do |n|
            ratio =
              if n.zero?
                1.0
              else
                n / n.closest_lower_power_of_two.to_f
              end

            MusicEdo::Degree.new(n, ratio)
          end

        new(degrees)
      end
    end # class << self

    def initialize(degrees)
      @degrees_indexed_by_degree_number = degrees.each_with_object({}) do |degree, hash|
        hash[degree.degree_number] = degree
      end
    end

    # Return an array of the degrees that make up this temperment. By default
    # we will not include the 0th degree.
    def degrees(with_zero: false)
      filtered_hash =
        if with_zero
          @degrees_indexed_by_degree_number
        else
          @degrees_indexed_by_degree_number.select do |degree_number, degree|
            degree_number != 0
          end
        end

      filtered_hash.values
    end
  end # Temperment

  class Degree
    NAMES = {
      12 => {
        0  => {
          full_name: 'unison',
          abbrev:    'P1'
        },
        1  => {
          full_name: 'minor second',
          abbrev:    'm2'
        },
        2  => {
          full_name: 'major second',
          abbrev:    'M2'
        },
        3  => {
          full_name: 'minor third',
          abbrev:    'm3'
        },
        4  => {
          full_name: 'major third',
          abbrev:    'M3'
        },
        5  => {
          full_name: 'perfect fourth',
          abbrev:    'P4'
        },
        6  => {
          full_name: 'Tritone',
          abbrev:    'd5'
        },
        7  => {
          full_name: 'perfect fifth',
          abbrev:    'P5'
        },
        8  => {
          full_name: 'minor sixth',
          abbrev:    'm6'
        },
        9  => {
          full_name: 'major sixth',
          abbrev:    'M6'
        },
        10 => {
          full_name: 'minor seventh',
          abbrev:    'm7'
        },
        11 => {
          full_name: 'major seventh',
          abbrev:    'M7'
        }
      }
    }

    attr_reader :degree_number
    attr_reader :ratio_from_degree_zero

    alias_method :ratio, :ratio_from_degree_zero

    def initialize(degree_number, ratio_from_degree_zero)
      @degree_number          = degree_number
      @ratio_from_degree_zero = ratio_from_degree_zero
    end

    # Subtract 1 degree from another which will return a special PitchDifference
    # object.
    def -(other)
      MusicEdo::PitchDifference.new(self, other)
    end

    # Find what is the closest in pitch to another degree in another
    # temperment.
    def closest_degree_in(temperment)
      temperment.degrees.min do |degree_a, degree_b|
        # Compare the differences between the 2 degrees to find the
        # one with the smaller difference.
        (self - degree_a) <=> (self - degree_b)
      end
    end

    def edo_12_abbrev
      NAMES.dig(12, @degree_number, :abbrev)
    end

    def to_s
      sprintf("(%-2d, %f)", @degree_number, @ratio_from_degree_zero)
    end
  end # Degree

  class PitchDifference
    def initialize(degree_a, degree_b)
      @degree_a = degree_a
      @degree_b = degree_b
    end

    # Raw difference in ratio.
    def raw
      @degree_a.ratio - @degree_b.ratio
    end

    # Difference in cents(12-edo definition of cents). This is a logarithmic
    # scale.
    def cents
      frequency_ratio = (@degree_a.ratio / @degree_b.ratio.to_f)
      1_200 * Math.log(frequency_ratio, 2)
    end

    # Comparison with another PitchDifference. Compare the absolute values to
    # get the real maginitude. So a difference of +10 is smaller than -20
    # for example.
    def <=>(other)
      self.raw.abs <=> other.raw.abs
    end
  end # PitchDifference
end # MusicEdo

harmonic_series_32 = MusicEdo::Temperment.generate_harmonic_series(32)
edo_12             = MusicEdo::Temperment.generate_edo(12)

[15].each do |n_edo|
  n_edo_temperment = MusicEdo::Temperment.generate_edo(n_edo)

  header_line    = StringIO.new
  my_degree_line = StringIO.new
  my_ratio_line  = StringIO.new

  edo_12_header_line      = StringIO.new
  edo_12_ratio_line       = StringIO.new
  edo_12_degree_name_line = StringIO.new
  edo_12_cents_line       = StringIO.new

  harmonic_series_header_line = StringIO.new
  harmonic_series_ratio_line  = StringIO.new
  harmonic_series_name_line   = StringIO.new
  harmonic_series_cents_line  = StringIO.new

  cell_width    = 15
  printf_string = "%#{cell_width}s"

  n_edo_temperment.degrees.each do |degree|
    edo_12_degree          = degree.closest_degree_in(edo_12)
    harmonic_series_degree = degree.closest_degree_in(harmonic_series_32)

    # n-edo
    header_line.print('+'*cell_width)
    my_degree_line.printf(printf_string, degree.degree_number)
    my_ratio_line.printf(printf_string, degree.ratio.round(5))

    # Comparison to 12-edo
    diff = degree - edo_12_degree
    cents = diff.cents.round

    edo_12_header_line.print('-'*cell_width)
    edo_12_ratio_line.printf(printf_string, edo_12_degree.ratio.round(5))
    edo_12_degree_name_line.printf(printf_string, edo_12_degree.edo_12_abbrev)
    edo_12_cents_line.printf(printf_string, cents)

    # Comparison to Harmonic Series
    diff = degree - harmonic_series_degree
    cents = diff.cents.round

    harmonic_series_header_line.print('-'*cell_width)
    harmonic_series_ratio_line.printf(printf_string, harmonic_series_degree.ratio.round(5))
    harmonic_series_name_line.printf(printf_string, harmonic_series_degree.degree_number)
    harmonic_series_cents_line.printf(printf_string, cents)
  end

  puts header_line.string
  puts my_degree_line.string
  puts my_ratio_line.string

  puts edo_12_header_line.string
  puts edo_12_ratio_line.string
  puts edo_12_degree_name_line.string
  puts edo_12_cents_line.string

  puts harmonic_series_header_line.string
  puts harmonic_series_ratio_line.string
  puts harmonic_series_name_line.string
  puts harmonic_series_cents_line.string
end
