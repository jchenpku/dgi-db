class GeneGroupsController < ApplicationController
  def show
    @title = params[:name]
    @gene_group = DataModel::GeneGroup.where(name: params[:name]).first
    @gene_group_presenter = GeneGroupPresenter.new(@gene_group)
  end

  def names
    cache_key = "gene_group_names"
    if Rails.cache.exist?(cache_key)
      @names = Rails.cache.fetch(cache_key)
    else
      @names = DataModel::GeneGroup.pluck(:name)
      Rails.cache.write(cache_key, @names, expires_in: 30.minutes)
    end
    respond_to do |format|
      format.json {render json:  @names.to_json}
    end
  end

  def druggable_gene_category
    @gene_groups = LookupFamilies.find_gene_groups_for_families(params[:name])
    @title = "Genes in the #{params[:name]} family"
    @druggable_gene_categories_active = "active"
    @family_name = params[:name]
  end

  def druggable_gene_categories
    @category_names = LookupFamilies.get_uniq_family_names
    @title = "Druggable Gene Categories"
    @druggable_gene_categories_active = "active"
  end

  def categories_search_results
    @search_categories_active = "active"
    combine_input_genes(params)
    validate_search_request(params)

    search_results = LookupGenes.find(params, :for_gene_families)
    @search_results = GeneFamilySearchResultsPresenter.new(search_results, params)
    if params[:outputFormat] == 'tsv'
      generate_tsv_headers('gene_families_export.tsv')
      render 'gene_families_export.tsv', content_type: 'text/tsv', layout: false
    end
  end

  private
  def validate_search_request(params)
    bad_request("Please enter at least one gene family to search!") unless params[:gene_names].size > 0
    bad_request("You must upload a plain text formated file") if params[:geneFile] && !validate_file_format('text/plain;', params[:geneFile].tempfile.path)
  end

end
